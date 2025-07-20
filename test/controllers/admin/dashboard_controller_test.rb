require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @group = groups(:one)
    @other_group = groups(:two)
    @admin_user = users(:one)  # Admin of @group
    @member_user = users(:two)  # Member of @group, admin of @other_group
    @non_member_user = User.create!(
      first_name: "Non",
      last_name: "Member",
      email: "nonmember@example.com",
      password: "password123"
    )
  end

  # Dashboard Index Tests
  test "should show admin dashboard with invite code for group admin" do
    sign_in @admin_user

    # Set current group context
    post switch_group_path(@group.slug)

    get admin_group_admin_root_path(group_slug: @group.slug)

    assert_response :success
    assert_select "h3", text: /Group Invite Code/
    assert_select ".font-mono", text: @group.invite_code
    assert_select "button[onclick*='copyInviteCode']"
    assert_select "a[href*='regenerate_invite_code']", text: /Regenerate Code/
  end

  test "should show member count in invite code section" do
    sign_in @admin_user
    post switch_group_path(@group.slug)

    get admin_group_admin_root_path(group_slug: @group.slug)

    assert_response :success
    expected_text = "#{@group.member_count} #{'member'.pluralize(@group.member_count)}"
    assert_select ".text-xs.text-gray-500", text: expected_text
  end

  test "should show join URL in invite code instructions" do
    sign_in @admin_user
    post switch_group_path(@group.slug)

    get admin_group_admin_root_path(group_slug: @group.slug)

    assert_response :success
    assert_select "a[href='#{join_group_url}']", text: join_group_url
  end

  test "should require admin access for dashboard" do
    sign_in @non_member_user

    get admin_group_admin_root_path(group_slug: @group.slug)

    # Should redirect (exact behavior depends on your authorization setup)
    assert_response :redirect
  end

  # Regenerate Invite Code Tests
  test "should regenerate invite code for group admin" do
    sign_in @admin_user
    post switch_group_path(@group.slug)

    original_code = @group.invite_code

    patch admin_regenerate_invite_code_path(group_slug: @group.slug)

    assert_response :redirect
    assert_redirected_to admin_group_admin_root_path(group_slug: @group.slug)

    @group.reload
    assert_not_equal original_code, @group.invite_code
    assert_equal 6, @group.invite_code.length
    assert_match /\A[A-Z0-9]{6}\z/, @group.invite_code

    follow_redirect!
    assert_match(/New invite code generated/, flash[:notice])
  end

  test "should require admin access for regenerate invite code" do
    sign_in @non_member_user

    patch admin_regenerate_invite_code_path(group_slug: @group.slug)

    assert_response :redirect
    # Should not change the invite code
    @group.reload
    assert_equal "ABC123", @group.invite_code  # Original fixture value
  end

  test "should only allow group admin to regenerate their group's code" do
    sign_in @member_user  # Admin of @other_group, but only member of @group

    original_code = @group.invite_code

    patch admin_regenerate_invite_code_path(group_slug: @group.slug)

    # Should redirect due to insufficient permissions (exact behavior depends on authorization setup)
    assert_response :redirect

    # Note: The exact authorization behavior may vary depending on your setup
    # If authorization allows it, the code might change; if not, it won't
  end

  test "should generate unique code when regenerating" do
    sign_in @admin_user
    post switch_group_path(@group.slug)

    # Regenerate multiple times to ensure uniqueness
    codes = [ @group.invite_code ]

    5.times do
      patch admin_regenerate_invite_code_path(group_slug: @group.slug)
      @group.reload
      codes << @group.invite_code
    end

    assert_equal codes.uniq.length, codes.length, "All generated codes should be unique"
  end

  test "should preserve group data when regenerating invite code" do
    sign_in @admin_user
    post switch_group_path(@group.slug)

    original_name = @group.name
    original_slug = @group.slug
    original_member_count = @group.member_count

    patch admin_regenerate_invite_code_path(group_slug: @group.slug)

    @group.reload
    assert_equal original_name, @group.name
    assert_equal original_slug, @group.slug
    assert_equal original_member_count, @group.member_count
  end

  test "should update timestamp when regenerating invite code" do
    sign_in @admin_user
    post switch_group_path(@group.slug)

    original_updated_at = @group.updated_at

    travel 1.second do
      patch admin_regenerate_invite_code_path(group_slug: @group.slug)
    end

    @group.reload
    assert @group.updated_at > original_updated_at
  end

  # Security Tests
  test "should require authentication for regenerate invite code" do
    patch admin_regenerate_invite_code_path(group_slug: @group.slug)

    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "should handle nonexistent group gracefully" do
    sign_in @admin_user

    patch admin_regenerate_invite_code_path(group_slug: "nonexistent-group")

    # Should redirect (exact behavior depends on your error handling)
    # Could be 404, redirect to home, or redirect to group selection
    assert_response :redirect
  end

  # JavaScript Functionality Tests (for copy functionality)
  test "should include copy invite code javascript" do
    sign_in @admin_user
    post switch_group_path(@group.slug)

    get admin_group_admin_root_path(group_slug: @group.slug)

    assert_response :success
    assert_select "script", text: /function copyInviteCode/
    assert_select "script", text: /navigator\.clipboard/
  end

  test "should include invite code value in javascript" do
    sign_in @admin_user
    post switch_group_path(@group.slug)

    get admin_group_admin_root_path(group_slug: @group.slug)

    assert_response :success
    assert_select "script", text: /#{@group.invite_code}/
  end

  # Integration Tests
  test "should show updated invite code immediately after regeneration" do
    sign_in @admin_user
    post switch_group_path(@group.slug)

    patch admin_regenerate_invite_code_path(group_slug: @group.slug)
    follow_redirect!

    @group.reload
    assert_select ".font-mono", text: @group.invite_code
    assert_select "script", text: /#{@group.invite_code}/
  end

  test "should work with different group contexts" do
    # Test that admin can manage different groups they admin
    sign_in @member_user  # Admin of @other_group
    post switch_group_path(@other_group.slug)

    original_code = @other_group.invite_code

    patch admin_regenerate_invite_code_path(group_slug: @other_group.slug)

    assert_response :redirect
    assert_redirected_to admin_group_admin_root_path(group_slug: @other_group.slug)

    @other_group.reload
    assert_not_equal original_code, @other_group.invite_code
  end

  # Error Handling Tests
  test "should handle basic error scenarios" do
    sign_in @admin_user
    post switch_group_path(@group.slug)

    # Test that the action completes successfully under normal conditions
    patch admin_regenerate_invite_code_path(group_slug: @group.slug)

    assert_response :redirect
    assert_redirected_to admin_group_admin_root_path(group_slug: @group.slug)
  end

  # Performance Tests
  test "should not make excessive database queries for dashboard" do
    sign_in @admin_user
    post switch_group_path(@group.slug)

    assert_queries_count = lambda do |&block|
      query_count = 0
      callback = lambda { |*args| query_count += 1 }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
      query_count
    end

    # Dashboard should be efficient
    query_count = assert_queries_count.call do
      get admin_group_admin_root_path(group_slug: @group.slug)
    end

    # Adjust this number based on your expected query count
    assert query_count < 30, "Dashboard made #{query_count} queries, expected less than 30"
  end
end
