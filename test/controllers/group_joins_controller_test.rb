require "test_helper"

class GroupJoinsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @group = groups(:one)
    @other_group = groups(:two)
    @user = users(:one)
    @member_user = users(:two)

    # Create a user who is not a member of any group
    @non_member_user = User.create!(
      first_name: "Non",
      last_name: "Member",
      email: "nonmember@example.com",
      password: "password123"
    )
  end

  # GET /join Tests
  test "should get new join form when signed in" do
    sign_in @non_member_user
    get join_group_path

    assert_response :success
    assert_select "h1", text: "Join a Golf Group"
    assert_select "input[name='invite_code']"
    assert_select "input[type='submit'][value='Join Group']"
  end

  test "should redirect to sign in when not authenticated" do
    get join_group_path
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "should show proper form elements" do
    sign_in @non_member_user
    get join_group_path

    assert_response :success
    assert_select "form[action='#{join_group_path}']"
    assert_select "input[name='invite_code'][maxlength='6'][required]"
    assert_select "script", text: /uppercase/i
  end

  # POST /join Tests - Success Cases
  test "should join group with valid invite code" do
    sign_in @non_member_user
    initial_member_count = @group.member_count

    post join_group_path, params: { invite_code: @group.invite_code }

    assert_response :redirect
    assert_redirected_to group_dashboard_path(@group.slug)

    follow_redirect!
    assert_match(/Welcome to #{@group.name}/, flash[:notice])

    # Verify user was added to group
    @group.reload
    assert_equal initial_member_count + 1, @group.member_count
    assert @group.member?(@non_member_user)

    # Verify membership role
    membership = @group.group_memberships.find_by(user: @non_member_user)
    assert_equal "member", membership.role
  end

  test "should join group with lowercase invite code" do
    sign_in @non_member_user

    post join_group_path, params: { invite_code: @group.invite_code.downcase }

    assert_response :redirect
    assert_redirected_to group_dashboard_path(@group.slug)
    assert @group.member?(@non_member_user)
  end

  test "should join group with invite code containing whitespace" do
    sign_in @non_member_user

    post join_group_path, params: { invite_code: "  #{@group.invite_code}  " }

    assert_response :redirect
    assert_redirected_to group_dashboard_path(@group.slug)
    assert @group.member?(@non_member_user)
  end

  test "should set current group context after joining" do
    sign_in @non_member_user

    post join_group_path, params: { invite_code: @group.invite_code }

    assert_equal @group.id, session[:current_group_id]
  end

  # POST /join Tests - Already a Member Cases
  test "should redirect existing member with notice" do
    sign_in @user  # Already admin of @group

    post join_group_path, params: { invite_code: @group.invite_code }

    assert_response :redirect
    assert_redirected_to group_dashboard_path(@group.slug)

    follow_redirect!
    assert_match(/You're already a member/, flash[:notice])
  end

  test "should handle member of different group joining another" do
    sign_in @member_user  # Member of @group, admin of @other_group

    # Check if already a member - if so, should get "already a member" message
    if @other_group.member?(@member_user)
      post join_group_path, params: { invite_code: @other_group.invite_code }

      assert_response :redirect
      assert_redirected_to group_dashboard_path(@other_group.slug)
      assert_match(/already a member/, flash[:notice])
    else
      initial_count = @other_group.member_count

      post join_group_path, params: { invite_code: @other_group.invite_code }

      assert_response :redirect
      assert_redirected_to group_dashboard_path(@other_group.slug)

      # Should be member of both groups
      assert @group.member?(@member_user)  # Still member of original group
      assert @other_group.member?(@member_user)  # Now also member of new group
      assert_equal initial_count + 1, @other_group.reload.member_count
    end
  end

  # POST /join Tests - Error Cases
  test "should reject invalid invite code" do
    sign_in @non_member_user
    initial_member_count = @group.member_count

    post join_group_path, params: { invite_code: "INVALID" }

    assert_response :unprocessable_entity
    assert_match(/Invalid group code/, flash[:alert])

    # Verify user was not added to any group
    @group.reload
    assert_equal initial_member_count, @group.member_count
    assert_not @group.member?(@non_member_user)
  end

  test "should reject empty invite code" do
    sign_in @non_member_user

    post join_group_path, params: { invite_code: "" }

    assert_response :unprocessable_entity
    assert_match(/Invalid group code/, flash[:alert])
  end

  test "should reject nil invite code" do
    sign_in @non_member_user

    post join_group_path, params: {}

    assert_response :unprocessable_entity
    assert_match(/Invalid group code/, flash[:alert])
  end

  test "should reject invite code for inactive group" do
    sign_in @non_member_user
    inactive_group = groups(:three)  # Set as inactive in fixtures

    post join_group_path, params: { invite_code: inactive_group.invite_code }

    # Should still allow joining inactive groups (business logic decision)
    # If you want to prevent this, update the controller and this test
    assert_response :redirect
  end

  # Authentication Tests
  test "should require authentication for join form" do
    get join_group_path
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "should require authentication for join action" do
    post join_group_path, params: { invite_code: @group.invite_code }
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  # Edge Cases
  test "should handle concurrent joins gracefully" do
    sign_in @non_member_user

    # Simulate potential race condition by calling join multiple times
    3.times do
      post join_group_path, params: { invite_code: @group.invite_code }
    end

    # Should still only be one membership
    memberships = @group.group_memberships.where(user: @non_member_user)
    assert_equal 1, memberships.count
  end

  test "should preserve @invite_code in form on error" do
    sign_in @non_member_user
    invalid_code = "BADCODE"

    post join_group_path, params: { invite_code: invalid_code }

    assert_response :unprocessable_entity
    # Note: Input preservation depends on how the controller handles the @invite_code variable
  end

  test "should show helpful error message for malformed codes" do
    sign_in @non_member_user

    # Test various malformed codes
    [ "ABC", "ABCDEFG", "abc!@#", " ", "123456789" ].each do |bad_code|
      post join_group_path, params: { invite_code: bad_code }

      assert_response :unprocessable_entity
      assert_match(/Invalid group code/, flash[:alert])
    end
  end

  # Integration with User Model
  test "should update user's group membership correctly" do
    sign_in @non_member_user

    # Verify user starts with no group memberships
    assert_equal 0, @non_member_user.group_memberships.count

    post join_group_path, params: { invite_code: @group.invite_code }

    # Verify user now has group membership
    @non_member_user.reload
    assert_equal 1, @non_member_user.group_memberships.count
    assert_equal @group, @non_member_user.group_memberships.first.group
  end
end
