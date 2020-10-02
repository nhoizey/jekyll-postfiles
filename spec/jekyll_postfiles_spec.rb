require "spec_helper"

describe Jekyll::PostFiles do
  let(:page)      { make_page }
  let(:site)      { make_site }
  let(:post)      { make_post }
  let(:context)   { make_context(:page => page, :site => site) }
  let(:url)       { "" }

  before do
    Jekyll.logger.log_level = :error
  end

  it "copies files" do
    site.process
    expect(Pathname.new(File.expand_path('', dest_dir))).to exist
  end
end
