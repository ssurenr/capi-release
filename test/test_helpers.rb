def create_executable(script)
  tmp_file = Tempfile.new("backup_or_restore_script")
  tmp_file.write(script)
  tmp_file.close

  FileUtils.chmod(0755, tmp_file.path)

  tmp_file.path
end

def run_script_with_directories(script, data_dir, artifact_dir)
  system("BLOBSTORE_OWNER=`id --user --name` " +
    "BLOBSTORE_OWNER_GROUP=`id --group --name` " +
    "BBR_ARTIFACT_DIRECTORY=#{artifact_dir} " +
    "BOSH_DATA_DIRECTORY=#{data_dir} " +
    "#{script}")
end


def render_bosh_template_with_links(job_name, template, links)
  release_path = File.join(File.dirname(__FILE__), '../')
  release = Bosh::Template::Test::ReleaseDir.new(release_path)
  job = release.job(job_name)
  template = job.template(template)
  rendered_config = template.render({}, consumes: links)

  create_executable(rendered_config)
end