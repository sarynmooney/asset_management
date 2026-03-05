class Api::V1::AssetsController < ApplicationController
  def show
    asset = Asset.find(params[:id])
    render json: asset_payload(asset)
  rescue ActiveRecord::RecordNotFound
      render json: { error: "Asset not found" }, status: :not_found
  end

  private

  def asset_payload(asset)
    company = asset.company
    {
      asset: {
        id: asset.id,
        name: asset.name,
        asset_type: asset.asset_type,
        serial_number: asset.serial_number,
        purchase_date: asset.purchase_date&.to_s,
        company_name: company.name,
        company_contact_email: company_contact_email_for(company),
        maintenance_count: asset.maintenance_records.count,
        total_maintenance_cost: asset.maintenance_records.sum(:cost).to_f,
        last_maintenance_date: last_maintenance_date_for(asset),
        software_licenses: asset.software_licenses.map { |license| software_license_summary(license) },
        recent_notes: asset.notes.order(created_at: :desc).limit(10).includes(:author).map { |note| note_summary(note) }
      }
    }
  end

  def company_contact_email_for(company)
    contact = company.contacts.find_by(role: "primary") || company.contacts.order(:id).first
    contact&.email
  end

  def last_maintenance_date_for(asset)
    date = asset.maintenance_records.order(performed_at: :desc).pick(:performed_at)
    date&.to_date&.to_s
  end

  def software_license_summary(license)
    {
      id: license.id,
      software_name: license.software_name,
      expiration_date: license.expiration_date.to_s,
      days_until_expiration: (license.expiration_date - Date.current).to_i,
      expired: license.expiration_date < Date.current
    }
  end

  def note_summary(note)
    {
      id: note.id,
      content: note.content,
      author_name: note.author.name,
      created_at: note.created_at.iso8601
    }
  end
end
