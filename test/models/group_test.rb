require "test_helper"

class GroupTest < ActiveSupport::TestCase
  def setup
    @group = groups(:one)
    @user = users(:one)
  end

  # Invite Code Generation Tests
  test "should generate invite code on creation" do
    group = Group.new(
      name: "Test Golf Club",
      slug: "test-golf-club",
      description: "A test golf club",
      active: true
    )

    assert group.save
    assert_not_nil group.invite_code
    assert_equal 6, group.invite_code.length
    assert_match /\A[A-Z0-9]{6}\z/, group.invite_code
  end

  test "should not generate invite code if one already exists" do
    original_code = @group.invite_code
    @group.save
    assert_equal original_code, @group.invite_code
  end

  test "should automatically generate invite code when blank" do
    group = Group.new(
      name: "Test Golf Club",
      slug: "test-golf-club",
      description: "A test golf club",
      active: true,
      invite_code: ""  # Start with blank code
    )

    assert group.save
    assert_not_nil group.invite_code
    assert_equal 6, group.invite_code.length
  end

  test "should validate invite code length" do
    @group.invite_code = "ABC12"  # Too short
    assert_not @group.valid?
    assert_includes @group.errors[:invite_code], "is the wrong length (should be 6 characters)"

    @group.invite_code = "ABC1234"  # Too long
    assert_not @group.valid?
    assert_includes @group.errors[:invite_code], "is the wrong length (should be 6 characters)"
  end

  test "should validate invite code uniqueness" do
    existing_code = @group.invite_code

    new_group = Group.new(
      name: "Another Golf Club",
      slug: "another-golf-club",
      description: "Another test golf club",
      active: true,
      invite_code: existing_code
    )

    assert_not new_group.valid?
    assert_includes new_group.errors[:invite_code], "has already been taken"
  end

  # Find by Invite Code Tests
  test "should find group by invite code" do
    found_group = Group.find_by_invite_code("ABC123")
    assert_equal @group, found_group
  end

  test "should find group by invite code case insensitive" do
    found_group = Group.find_by_invite_code("abc123")
    assert_equal @group, found_group
  end

  test "should find group by invite code with whitespace" do
    found_group = Group.find_by_invite_code("  ABC123  ")
    assert_equal @group, found_group
  end

  test "should return nil for invalid invite code" do
    found_group = Group.find_by_invite_code("INVALID")
    assert_nil found_group
  end

  test "should return nil for nil invite code" do
    found_group = Group.find_by_invite_code(nil)
    assert_nil found_group
  end

  test "should return nil for empty invite code" do
    found_group = Group.find_by_invite_code("")
    assert_nil found_group
  end

  # Regenerate Invite Code Tests
  test "should regenerate invite code" do
    original_code = @group.invite_code
    @group.regenerate_invite_code!

    assert_not_equal original_code, @group.invite_code
    assert_equal 6, @group.invite_code.length
    assert_match /\A[A-Z0-9]{6}\z/, @group.invite_code
  end

  test "should save group when regenerating invite code" do
    original_updated_at = @group.updated_at
    travel 1.second do
      @group.regenerate_invite_code!
    end

    @group.reload
    assert @group.updated_at > original_updated_at
  end

  # Member Management Tests
  test "should add member with invite code join" do
    new_user = User.create!(
      first_name: "Test",
      last_name: "User",
      email: "test@example.com",
      password: "password123"
    )

    initial_count = @group.member_count
    membership = @group.add_member(new_user, role: "member")

    assert membership.persisted?
    assert_equal "member", membership.role
    assert_equal initial_count + 1, @group.member_count
    assert @group.member?(new_user)
  end

  test "should not duplicate membership when adding existing member" do
    initial_count = @group.member_count
    membership = @group.add_member(@user, role: "member")

    # Should return existing membership, not create new one
    assert_equal initial_count, @group.member_count
    assert_equal "admin", membership.role  # Existing role should be preserved
  end

  # Code Generation Helper Tests
  test "should generate unique codes" do
    codes = []

    # Generate multiple codes and ensure they're unique
    100.times do
      group = Group.new(
        name: "Test Club #{codes.length}",
        slug: "test-club-#{codes.length}",
        active: true
      )
      group.save!
      codes << group.invite_code
    end

    assert_equal codes.uniq.length, codes.length, "Generated codes should be unique"
  end

  test "should generate codes with correct format" do
    group = Group.create!(
      name: "Format Test Club",
      slug: "format-test-club",
      active: true
    )

    # Should be exactly 6 characters, alphanumeric, uppercase
    assert_match /\A[A-Z0-9]{6}\z/, group.invite_code
    assert_equal group.invite_code, group.invite_code.upcase
  end

  # Integration with Member Count
  test "should reflect member count correctly" do
    assert_equal 2, @group.member_count  # From fixtures: John (admin) and Jane (member)

    new_user = User.create!(
      first_name: "New",
      last_name: "Member",
      email: "new@example.com",
      password: "password123"
    )

    @group.add_member(new_user, role: "member")
    assert_equal 3, @group.member_count
  end
end
