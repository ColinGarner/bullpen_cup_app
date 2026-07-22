class RequireGroupOnTournaments < ActiveRecord::Migration[8.0]
  # Tournament#belongs_to :group is non-optional and TenantScoped validates
  # presence in Ruby. The DB never enforced it. Verified zero null rows in
  # dev before writing this migration; verify in production before deploy.
  def change
    change_column_null :tournaments, :group_id, false
  end
end
