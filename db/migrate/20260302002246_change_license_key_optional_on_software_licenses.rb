class ChangeLicenseKeyOptionalOnSoftwareLicenses < ActiveRecord::Migration[8.0]
  def change
    change_column_null :software_licenses, :license_key, true
  end
end
