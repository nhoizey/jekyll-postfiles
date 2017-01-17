require "jekyll-postfiles/version"
require "jekyll"

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


      post_path = post.path
      site = post.site
        if filepath != postpath
          filedir, filename = File.split(filepath[sitesrcdir.length..-1])
      site_src_dir = site.source
      post_dir = File.dirname(post_path)
      dest_dir = File.dirname(post.destination(""))
      contents = Dir.glob(File.join(post_dir, '**', '*')) do |filepath|
      # Count other Markdown files in the same directory
      other_md_count = 0
      other_md = Dir.glob(File.join(post_dir, '*.{md,markdown}'), File::FNM_CASEFOLD) do |mdfilepath|
        if mdfilepath != post_path
          other_md_count += 1
        end
      end

          site.static_files <<
            PostFile.new(site, site_src_dir, filedir, filename, dest_dir)
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
