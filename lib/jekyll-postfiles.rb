require "jekyll-postfiles/version"
require "jekyll"
require "pathname"

module Jekyll

  class PostFile < StaticFile

    # Initialize a new PostFile.
    #
    # site - The Site.
    # base - The String path to the <source>.
    # dir - The String path of the source directory of the file (rel <source>).
    # name - The String filename of the file.
    def initialize(site, base, dir, name, dest)
      super(site, base, dir, name)
      @name = name
      @dest = dest
    end

    # Obtain destination path.
    #
    # dest - The String path to the destination dir.
    #
    # Returns destination file path.
    def destination(dest)
      File.join(@dest, @name)
    end
  end

  class PostFileGenerator < Generator

    # Copy the files from post's folder.
    #
    # post - A Post which may have associated content.
    def copy_post_files(post)

      post_path = Pathname.new post.path
      site = post.site
      site_src_dir = Pathname.new site.source

      # Jekyll.logger.warn(
      #   "[PostFiles]",
      #   "Current post: #{post_path[site_src_dir.length..-1]}"
      # )

      post_dir = post_path.dirname
      dest_dir = Pathname.new(post.destination("")).dirname

      # Count other Markdown files in the same directory
      other_md_count = 0
      other_md = Dir.glob(post_dir + '*.{md,markdown}', File::FNM_CASEFOLD) do |mdfilepath|
        if mdfilepath != post_path.to_path
          other_md_count += 1
        end
      end

      contents = Dir.glob(post_dir + '**/*') do |filepath|
        if filepath != post_path \
            && !File.directory?(filepath) \
            && !File.fnmatch?('*.{md,markdown}', filepath, File::FNM_EXTGLOB | File::FNM_CASEFOLD)
          filepath = Pathname.new(filepath)
          # Jekyll.logger.warn(
          #   "[PostFiles]",
          #   "-> attachment: #{filepath[site_src_dir.length..-1]}"
          # )
          if other_md_count > 0
            Jekyll.logger.abort_with(
              "[PostFiles]",
              "Sorry, there can be only one Markdown file in each directory containing other assets to be copied by jekyll-postfiles"
            )
          end
          relpath = filepath.relative_path_from(site_src_dir)
          filedir, filename = relpath.dirname, relpath.basename

          absfiledir = site_src_dir + filedir
          new_dir = absfiledir.relative_path_from(post_dir)
          site.static_files <<
            PostFile.new(site, site_src_dir, filedir, filename, (dest_dir + new_dir).to_path)
        end
      end
    end

    # Generate content by copying files associated with each post.
    def generate(site)
      site.posts.docs.each do |post|
        copy_post_files(post)
      end
    end
  end

end
