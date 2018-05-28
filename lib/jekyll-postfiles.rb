require "jekyll-postfiles/version"
require "jekyll"
require "pathname"

module Jekyll

  # there's a bug in the regex Document::DATE_FILENAME_MATCHER:
  #   %r!^(?:.+/)*(\d{2,4}-\d{1,2}-\d{1,2})-(.*)(\.[^.]+)$!
  # used by:
  #   jekyll/lib/jekyll/readers/post_reader.rb#read_posts
  # which ultimately populates:
  #   site.posts.docs
  #
  # the original code's intention was to match:
  #   all files with a date in the name
  # but it accidentally matches also:
  #   all files immediately within a directory whose name contains a date
  #
  # our plugin changes the regex, to:
  #   avoid false positive when directory name matches date regex
  Hooks.register :site, :after_reset do |site|
    # Suppress warning messages.
    original_verbose, $VERBOSE = $VERBOSE, nil
    Document.const_set('DATE_FILENAME_MATCHER', PostFileGenerator::FIXED_DATE_FILENAME_MATCHER)
    # Activate warning messages again.
    $VERBOSE = original_verbose
  end

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

    FIXED_DATE_FILENAME_MATCHER = %r!^(?:.+/)*(\d{2,4}-\d{1,2}-\d{1,2})-([^/]*)(\.[^.]+)$!

    # _posts/
    #   2018-01-01-whatever.md     # there's a date on this filename, so it will be treated as a post
    #                              # it's a direct descendant of _posts, so we do not treat it as an asset root
    #   somedir/
    #     2018-05-01-some-post.md  # there's a date on this filename, so it will be treated as a post.
    #                              # moreover, we will treat its dir as an asset root
    #     cool.svg                 # there's no date on this filename, so it will be treated as an asset
    #     undated.md               # there's no date on this filename, so it will be treated as an asset
    #     img/
    #       cool.png               # yes, even deeply-nested files are eligible to be copied.
    def generate(site)
      site_src_dir = Pathname.new site.source
      posts_src_dir = site_src_dir + '_posts'
      drafts_src_dir = site_src_dir + '_drafts'

      Jekyll.logger.warn("[PostFiles]", "_posts: #{posts_src_dir}")
      Jekyll.logger.warn("[PostFiles]", "docs: #{site.posts.docs.map(&:path)}")

      docs_with_dirs = site.posts.docs
        .reject{ |doc|
          Pathname.new(doc.path).dirname.instance_eval{ |dirname|
            [posts_src_dir, drafts_src_dir].reduce(false) {|acc, dir|
              acc || dirname.eql?(dir)
            }
          }
        }

      Jekyll.logger.warn("[PostFiles]", "asset_roots: #{docs_with_dirs.map{|doc| Pathname.new(doc.path).dirname}}")

      assets = docs_with_dirs.map{ |doc|
        dest_dir = Pathname.new(doc.destination("")).dirname
        Pathname.new(doc.path).dirname.instance_eval{ |asset_root|
          Dir[asset_root + '**/*']
            .reject{ |fname| fname =~ FIXED_DATE_FILENAME_MATCHER }
            .reject{ |fname| File.directory? fname }
            .map { |fname|
              path = Pathname.new fname
              relpath = path.relative_path_from(site_src_dir)
              filedir, filename = relpath.dirname, relpath.basename

              absfiledir = site_src_dir + filedir
              new_dir = absfiledir.relative_path_from(asset_root)
              PostFile.new(site, site_src_dir, filedir, filename, (dest_dir + new_dir).to_path)
            }
        }
      }.flatten

      site.static_files.concat(assets)
    end
  end

end
