require "application_system_test_case"

class GroupInviteCodesTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  def setup
    @group = groups(:one)
    @other_group = groups(:two)
    @admin_user = users(:one)  # Admin of @group
    @member_user = users(:two)  # Member of @group, admin of @other_group

    # Create a user who is not a member of any group
    @new_user = User.create!(
      first_name: "New",
      last_name: "Member",
      email: "newmember@example.com",
      password: "password123"
    )
  end

  # Complete Invite Workflow Tests
  test "complete invite code workflow from admin to new member" do
    # Step 1: Admin views their invite code
    login_as(@admin_user)
    visit root_path

    # Navigate to admin dashboard
    click_link "Switch to #{@group.name}"
    click_link "Admin"

    # Verify invite code is displayed
    assert_text "Group Invite Code"
    assert_text @group.invite_code
    assert_button "Regenerate Code"

    # Step 2: Get the invite code (simulate sharing)
    invite_code = @group.invite_code

    # Step 3: New user visits join page
    logout
    login_as(@new_user)
    visit join_group_path

    # Verify join form is displayed
    assert_text "Join a Golf Group"
    assert_field "Group Invite Code"

    # Step 4: Enter the invite code
    fill_in "Group Invite Code", with: invite_code
    click_button "Join Group"

    # Step 5: Verify successful join
    assert_text "Welcome to #{@group.name}!"
    assert_current_path group_dashboard_path(@group.slug)

    # Step 6: Verify user is now a member
    @group.reload
    assert @group.member?(@new_user)

    membership = @group.group_memberships.find_by(user: @new_user)
    assert_equal "member", membership.role
  end

  test "admin can regenerate invite code and new code works" do
    login_as(@admin_user)
    visit root_path
    click_link "Switch to #{@group.name}"
    click_link "Admin"

    # Get original invite code
    original_code = @group.invite_code
    assert_text original_code

    # Regenerate the code
    accept_confirm "Are you sure? This will invalidate the current code and anyone with the old code won't be able to join." do
      click_link "Regenerate Code"
    end

    # Verify new code is generated
    assert_text "New invite code generated:"
    @group.reload
    new_code = @group.invite_code
    assert_not_equal original_code, new_code
    assert_text new_code

    # Test that new code works
    logout
    login_as(@new_user)
    visit join_group_path

    fill_in "Group Invite Code", with: new_code
    click_button "Join Group"

    assert_text "Welcome to #{@group.name}!"
    assert @group.reload.member?(@new_user)
  end

  test "old invite code becomes invalid after regeneration" do
    login_as(@admin_user)
    visit root_path
    click_link "Switch to #{@group.name}"
    click_link "Admin"

    # Get original code
    original_code = @group.invite_code

    # Regenerate code
    accept_confirm do
      click_link "Regenerate Code"
    end

    # Try to use old code
    logout
    login_as(@new_user)
    visit join_group_path

    fill_in "Group Invite Code", with: original_code
    click_button "Join Group"

    # Should fail
    assert_text "Invalid group code"
    assert_not @group.reload.member?(@new_user)
  end

  # User Experience Tests
  test "invite code input is automatically uppercased" do
    login_as(@new_user)
    visit join_group_path

    # Type lowercase code
    fill_in "Group Invite Code", with: @group.invite_code.downcase

    # Field should automatically convert to uppercase
    assert_field "Group Invite Code", with: @group.invite_code.upcase
  end

  test "invite code form shows helpful validation" do
    login_as(@new_user)
    visit join_group_path

    # Try invalid code
    fill_in "Group Invite Code", with: "INVALID"
    click_button "Join Group"

    assert_text "Invalid group code. Please check the code and try again."
    assert_field "Group Invite Code", with: "INVALID"  # Preserves input
  end

  test "user already a member gets friendly message" do
    login_as(@member_user)  # Already a member of @group
    visit join_group_path

    fill_in "Group Invite Code", with: @group.invite_code
    click_button "Join Group"

    assert_text "You're already a member of #{@group.name}!"
    assert_current_path group_dashboard_path(@group.slug)
  end

  test "user can join multiple groups" do
    # First, join one group
    login_as(@new_user)
    visit join_group_path

    fill_in "Group Invite Code", with: @group.invite_code
    click_button "Join Group"
    assert_text "Welcome to #{@group.name}!"

    # Then join another group
    visit join_group_path
    fill_in "Group Invite Code", with: @other_group.invite_code
    click_button "Join Group"
    assert_text "Welcome to #{@other_group.name}!"

    # Verify memberships
    @new_user.reload
    assert @group.member?(@new_user)
    assert @other_group.member?(@new_user)
  end

  # Copy Functionality Tests
  test "admin can copy invite code with javascript" do
    login_as(@admin_user)
    visit root_path
    click_link "Switch to #{@group.name}"
    click_link "Admin"

    # Find the copy button (can't actually test clipboard, but can test UI)
    copy_button = find("button[onclick*='copyInviteCode']")
    assert copy_button.present?

    # The actual copying would need browser automation that supports clipboard
    # For now, we just verify the button exists and has the right attributes
    assert copy_button[:title] == "Copy code"
  end

  # Navigation and UI Tests
  test "home page shows join group option for users without groups" do
    login_as(@new_user)
    visit root_path

    # Should show onboarding with join option
    assert_text "Join a Golf Group"
    assert_text "Enter Group Code"
    assert_link "Enter Group Code", href: join_group_path
  end

  test "join form has proper styling and accessibility" do
    login_as(@new_user)
    visit join_group_path

    # Check for proper form elements
    assert_field "Group Invite Code", type: "text"
    code_input = find_field("Group Invite Code")
    assert_equal "6", code_input[:maxlength]
    assert code_input[:required]
    assert_equal "ABC123", code_input[:placeholder]

    # Check for helpful text
    assert_text "Group codes are 6 characters (letters and numbers)"
    assert_text "How it works"
    assert_text "Ask a group admin for the 6-character invite code"
  end

  test "admin dashboard shows complete invite instructions" do
    login_as(@admin_user)
    visit root_path
    click_link "Switch to #{@group.name}"
    click_link "Admin"

    # Check invite code section
    assert_text "Group Invite Code"
    assert_text "Share this code with people you want to invite"
    assert_text "How to invite:"
    assert_text "1. Share this code with new members"
    assert_text "2. They visit:"
    assert_text "3. They enter the code and join instantly!"

    # Check member count
    assert_text "#{@group.member_count} member"
  end

  # Error Handling Tests
  test "handles various invalid invite codes gracefully" do
    login_as(@new_user)
    visit join_group_path

    invalid_codes = [ "", "ABC", "ABCDEFG", "abc!@#", "123456789", "XXXXXX" ]

    invalid_codes.each do |code|
      fill_in "Group Invite Code", with: code
      click_button "Join Group"

      assert_text "Invalid group code"
      assert_current_path join_group_path
    end
  end

  test "works with whitespace in invite codes" do
    login_as(@new_user)
    visit join_group_path

    # Test with leading/trailing spaces
    fill_in "Group Invite Code", with: "  #{@group.invite_code}  "
    click_button "Join Group"

    assert_text "Welcome to #{@group.name}!"
    assert @group.reload.member?(@new_user)
  end

  # Authorization Tests
  test "non-authenticated users redirected to sign in" do
    visit join_group_path
    assert_current_path new_user_session_path

    visit admin_group_admin_root_path(group_slug: @group.slug)
    assert_current_path new_user_session_path
  end

  test "non-admin users cannot access admin dashboard" do
    login_as(@new_user)
    visit admin_group_admin_root_path(group_slug: @group.slug)

    # Should redirect away from admin area
    assert_not_equal admin_group_admin_root_path(group_slug: @group.slug), current_path
  end

  # Performance Tests
  test "join workflow is fast and responsive" do
    login_as(@new_user)

    start_time = Time.current
    visit join_group_path
    form_load_time = Time.current - start_time

    start_time = Time.current
    fill_in "Group Invite Code", with: @group.invite_code
    click_button "Join Group"
    join_time = Time.current - start_time

    # These are generous limits for system tests
    assert form_load_time < 5.seconds, "Join form took too long to load: #{form_load_time}s"
    assert join_time < 5.seconds, "Join process took too long: #{join_time}s"
  end

  # Helper method to simulate different browsers/devices
  test "invite code system works on mobile viewport" do
    # Simulate mobile viewport
    page.driver.resize_window(375, 667)  # iPhone dimensions

    login_as(@new_user)
    visit join_group_path

    # Form should still be usable
    assert_field "Group Invite Code"
    fill_in "Group Invite Code", with: @group.invite_code
    click_button "Join Group"

    assert_text "Welcome to #{@group.name}!"
  end

  private

  def login_as(user)
    sign_in user
  end

  def logout
    sign_out :user
  end
end
