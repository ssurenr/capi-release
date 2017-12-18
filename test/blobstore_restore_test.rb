require 'bosh/template/test'
require 'yaml'
require 'json'
require 'erb'


class TestRestoreTemplate < Test::Unit::TestCase
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

  def test_restore_with_all_folders
    links = [blobstore_directories_link]
    rendered_script_path = render_bosh_template_with_links('blobstore', 'bin/bbr/restore', links)

    Dir.mktmpdir do |data_dir|
      Dir.mktmpdir do |artifact_dir|
        FileUtils.mkdir_p([File.join(artifact_dir, "shared", "cc-packages", "new-package"),

                           File.join(artifact_dir, "shared", "cc-droplets", "a-droplet"),
                           File.join(artifact_dir, "shared", "cc-buildpacks", "a-buildpack"),

                           File.join(data_dir, "shared", "random-folder"),
                           File.join(data_dir, "shared", "cc-packages", "existing-package"),
                           File.join(data_dir, "shared", "cc-resources", "existing-resource")])

        success = run_script_with_directories(rendered_script_path, data_dir, artifact_dir)
        assert_true(success, "restore should be successful")

        assert_true(Dir.exists?(File.join(data_dir, "shared", "cc-packages")))
        assert_false(Dir.exists?(File.join(data_dir, "shared", "cc-packages", "existing-package")),
                     "existing packages removed")
        assert_true(Dir.exists?(File.join(data_dir, "shared", "cc-packages", "new-package")),
                    "packages copied over from backup")

        assert_true(Dir.exists?(File.join(data_dir, "shared", "cc-droplets", "a-droplet")),
                    "droplets are restored")
        assert_true(Dir.exists?(File.join(data_dir, "shared", "cc-buildpacks", "a-buildpack")),
                    "buildpacks are restored")

        assert_true(Dir.exists?(File.join(data_dir, "shared", "random-folder")),
                    "other folders not touched")
        assert_true(Dir.exists?(File.join(data_dir, "shared", "cc-resources", "existing-resource")),
                    "resources directory not touched")
      end
    end
  end

  def test_when_folders_are_missing
    links = [blobstore_directories_link]
    rendered_script_path = render_bosh_template_with_links('blobstore', 'bin/bbr/restore', links)

    Dir.mktmpdir do |data_dir|
      Dir.mktmpdir do |artifact_dir|
        FileUtils.mkdir_p(File.join(artifact_dir, "shared", "cc-buildpacks", "new-buildpacks"))

        FileUtils.mkdir_p(File.join(data_dir, "shared", "cc-droplets", "existing-droplet"))

        success = run_script_with_directories(rendered_script_path, data_dir, artifact_dir)
        assert_true(success, "restore should be successful")

        assert_true(Dir.exists?(File.join(data_dir, "shared", "cc-buildpacks", "new-buildpacks")),
                    "directory restored when not already in blobstore")

        assert_false(Dir.exists?(File.join(data_dir, "shared", "cc-droplets")),
                     "directory removed when not in artifact")

        assert_false(Dir.exists?(File.join(data_dir, "shared", "cc-packages")),
                     "directory not created when in neither artifact nor blobstore")
      end
    end
  end

  def test_it_hardlinks_the_files
    links = [blobstore_directories_link]
    rendered_script_path = render_bosh_template_with_links('blobstore', 'bin/bbr/restore', links)

    Dir.mktmpdir do |artifact_dir|
      Dir.mktmpdir do |data_dir|
        FileUtils.mkdir_p([File.join(artifact_dir, "shared", "cc-packages"),
                           File.join(artifact_dir, "shared", "cc-droplets"),
                           File.join(artifact_dir, "shared", "cc-buildpacks")])

        FileUtils.touch([File.join(artifact_dir, "shared", "cc-packages", "packages_file"),
                         File.join(artifact_dir, "shared", "cc-droplets", "droplet_file"),
                         File.join(artifact_dir, "shared", "cc-buildpacks", "buildpack_file")])

        FileUtils.mkdir_p(File.join(data_dir, "shared"))

        success = run_script_with_directories(rendered_script_path, data_dir, artifact_dir)
        assert_true(success, "restore script should succeed")

        ["shared/cc-packages/packages_file",
         "shared/cc-droplets/droplet_file",
         "shared/cc-buildpacks/buildpack_file"].each do |blob_file|
          assert_true(File.exists?(File.join(data_dir, blob_file)),File.join(data_dir, blob_file))
          assert_false(File.symlink?(File.join(data_dir, blob_file)))
          assert_true(File.identical?(
              File.join(artifact_dir, blob_file),
              File.join(data_dir, blob_file)))
        end
      end
    end
  end


  def test_restore_with_missing_links
    links = []

    assert_raise Bosh::Template::UnknownLink do
      render_bosh_template_with_links('blobstore', 'bin/bbr/restore', links)
    end
  end
end


