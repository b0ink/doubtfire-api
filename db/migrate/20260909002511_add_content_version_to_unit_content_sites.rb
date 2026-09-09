class AddContentVersionToUnitContentSites < ActiveRecord::Migration[8.0]
  def up
    unless column_exists?(:unit_content_sites, :content_version)
      add_column :unit_content_sites, :content_version, :string, limit: 64
    end

    UnitContentSite.reset_column_information
    UnitContentSite.find_each do |site|
      if File.file?(site.archive_path)
        site.content_version = UnitContentSite.content_version_for(site.archive_path, site.root_dir)
      else
        site.content_version = Digest::SHA256.hexdigest(
          "missing:#{site.id}:#{site.archive_path}:#{site.root_dir}:#{site.updated_at.to_f}"
        )
        say "Skipping extraction for unit content site #{site.id}: archive is missing"
      end

      site.save!(touch: false)
      site.extract_for_serving! if File.file?(site.archive_path)
    end

    change_column_null :unit_content_sites, :content_version, false
  end

  def down
    remove_column :unit_content_sites, :content_version if column_exists?(:unit_content_sites, :content_version)
  end
end
