require "spec_helper"

describe Jekyll::PostFiles do
  let(:page)      { make_page }
  let(:site)      { make_site }
  let(:post)      { make_post }
  let(:context)   { make_context(:page => page, :site => site) }
  let(:url)       { "" }

  before do
    Jekyll.logger.log_level = :error
    site.process
  end

  it "copies image from global assets folder" do
    expect(Pathname.new(File.expand_path('assets/jekyll.png', dest_dir))).to exist
  end

  it "copies image from post folder" do
    expect(Pathname.new(File.expand_path('2016/06/09/cloudflare.png', dest_dir))).to exist
  end
end
