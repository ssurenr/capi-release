require 'bosh/template/test'
require 'yaml'
require 'json'
require 'erb'


class TestBackupTemplate < Test::Unit::TestCase
  include Bosh::Template::Test

  def blobstore_directories_link
    Link.new(
        name: 'directories_to_backup',
        instances: [LinkInstance.new(address: 'api_instance')],
        properties: {
            "cc" => {
                "packages" => {"app_package_directory_key" => "cc-packages"},
                "droplets" => {"droplet_directory_key" => "cc-droplets"},
                "buildpacks" => {"buildpack_directory_key" => "cc-buildpacks"},
            },
        }
    )
  end

  def test_backup_with_all_folders
    links = [blobstore_directories_link]
    rendered_script_path = render_bosh_template_with_links('blobstore', 'bin/bbr/backup', links)

    Dir.mktmpdir do |artifact_dir|
      Dir.mktmpdir do |data_dir|
        FileUtils.mkdir_p([File.join(data_dir, "shared", "cc-packages"),
                           File.join(data_dir, "shared", "cc-droplets", "buildpack_cache"),
                           File.join(data_dir, "shared", "cc-buildpacks"),
                           File.join(data_dir, "shared", "cc-resources")])

        success = run_script_with_directories(rendered_script_path, data_dir, artifact_dir)
        assert_true(success, "Backup script should succeed")
        assert_true(Dir.exists?(File.join(artifact_dir, "shared", "cc-packages")))
        assert_true(Dir.exists?(File.join(artifact_dir, "shared", "cc-droplets")))
        assert_true(Dir.exists?(File.join(artifact_dir, "shared", "cc-buildpacks")))

        assert_false(Dir.exists?(File.join(artifact_dir, "shared", "cc-resources")))
        assert_false(Dir.exists?(File.join(artifact_dir, "shared", "cc-droplets", "buildpack_cache")),
                     "buildpack cache should be ignored")
      end
    end
  end

  def test_buildpack_cache_missing
    links = [blobstore_directories_link]
    rendered_script_path = render_bosh_template_with_links('blobstore', 'bin/bbr/backup', links)

    Dir.mktmpdir do |artifact_dir|
      Dir.mktmpdir do |data_dir|
        FileUtils.mkdir_p(File.join(data_dir, "shared", "cc-droplets"))

        success = run_script_with_directories(rendered_script_path, data_dir, artifact_dir)
        assert_true(success, "Backup script should succeed")
        assert_true(Dir.exists?(File.join(artifact_dir, "shared", "cc-droplets")), "copies over droplets without buildpacks")

      end
    end
  end

  def test_it_hardlinks_the_files
    links = [blobstore_directories_link]
    rendered_script_path = render_bosh_template_with_links('blobstore', 'bin/bbr/backup', links)

    Dir.mktmpdir do |artifact_dir|
      Dir.mktmpdir do |data_dir|
        FileUtils.mkdir_p([File.join(data_dir, "shared", "cc-packages"),
                           File.join(data_dir, "shared", "cc-droplets"),
                           File.join(data_dir, "shared", "cc-buildpacks")])

        FileUtils.touch([File.join(data_dir, "shared", "cc-packages", "packages_file"),
                         File.join(data_dir, "shared", "cc-droplets", "droplet_file"),
                         File.join(data_dir, "shared", "cc-buildpacks", "buildpack_file")])

        success = run_script_with_directories(rendered_script_path, data_dir, artifact_dir)
        assert_true(success, "Backup script should succeed")

        ["shared/cc-packages/packages_file", "shared/cc-droplets/droplet_file", "shared/cc-buildpacks/buildpack_file"].each do |blob_file|
          assert_true(File.exists?(File.join(artifact_dir, blob_file)))
          assert_false(File.symlink?(File.join(artifact_dir, blob_file)))
          assert_true(File.identical?(
              File.join(artifact_dir, blob_file),
              File.join(data_dir, blob_file)))
        end
      end
    end
  end

  def test_backup_with_missing_folders
    links = [blobstore_directories_link]
    rendered_script_path = render_bosh_template_with_links('blobstore', 'bin/bbr/backup', links)

    Dir.mktmpdir do |artifact_dir|
      Dir.mktmpdir do |data_dir|
        FileUtils.mkdir_p([File.join(data_dir, "shared", "cc-packages"),
                           File.join(data_dir, "shared", "cc-droplets"),
                           File.join(data_dir, "shared", "cc-droplets", "buildpack_cache")])

        success = run_script_with_directories(rendered_script_path, data_dir, artifact_dir)
        assert_true(success, "Backup script should succeed")
        assert_true(Dir.exists?(File.join(artifact_dir, "shared", "cc-packages")))
        assert_true(Dir.exists?(File.join(artifact_dir, "shared", "cc-droplets")))
        assert_false(Dir.exists?(File.join(artifact_dir, "shared", "cc-buildpacks")),
                     "directory missing from blobstore should not be present in artifact")
      end
    end
  end

  def test_backup_with_missing_links
    links = []

    assert_raise Bosh::Template::UnknownLink do
      render_bosh_template_with_links('blobstore', 'bin/bbr/backup', links)
    end
  end
end


