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

      postpath = post.path
      postdir = File.dirname(postpath)
      destdir = File.dirname(post.destination(""))

      site = post.site
      sitesrcdir = site.source
      contents = Dir.glob(File.join(postdir, '**', '*')) do |filepath|
        if filepath != postpath
          filedir, filename = File.split(filepath[sitesrcdir.length..-1])
          filereldir, filename = File.split(filepath[postdir.length..-1])
          if File.file?(filepath)
           site.static_files <<
             PostFile.new(site, sitesrcdir, filedir, filename, destdir + filereldir)
          end
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
