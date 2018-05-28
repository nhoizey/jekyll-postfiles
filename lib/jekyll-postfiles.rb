require "jekyll-postfiles/version"
require "jekyll"
require "pathname"

module Jekyll

  # we hook just after the initial site.posts.docs is proposed by:
  # jekyll/lib/jekyll/readers/post_reader.rb#read_posts
  #
  # Hooks.register :site, :post_read do |site|
  #   FIXED_DATE_FILENAME_MATCHER = %r!^(?:.+/)*(\d{2,4}-\d{1,2}-\d{1,2})-([^/]*)(\.[^.]+)$!
  #   site.posts.docs.concat(site.reader.post_reader.read_publishable)
  # end

  # there's a bug in the regex Document::DATE_FILENAME_MATCHER:
  #   %r!^(?:.+/)*(\d{2,4}-\d{1,2}-\d{1,2})-(.*)(\.[^.]+)$!
  # used by:
  #   jekyll/lib/jekyll/readers/post_reader.rb#read_posts
  # ultimately this populates:
  #   site.posts.docs
  #
  # the original code's intention was to match:
  #   all files with a date in the name
  # but it accidentally matches also:
  #   all files immediately within a directory whose name contains a date
  #
  # our plugin changes the regex
  #   - avoid false positive when directory name matches date regex
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

      Jekyll.logger.warn("[PostFiles]", "post_path: #{post_path}")
      Jekyll.logger.warn("[PostFiles]", "post_dir:  #{post_dir}")
      Jekyll.logger.warn("[PostFiles]", "post_dest: #{post.destination("")}")
      Jekyll.logger.warn("[PostFiles]", "dest_dir:  #{dest_dir}")

      Jekyll.logger.warn("[PostFiles]", "RETURN")
      return

      # Count other Markdown files in the same directory
      other_md_count = 0
      other_md = Dir.glob(post_dir + '*.{md,markdown}', File::FNM_CASEFOLD) do |mdfilepath|
        # Jekyll.logger.warn(
        #   "[PostFiles]",
        #   "mdfilepath: #{mdfilepath}; post_path.to_path: #{post_path.to_path}"
        # )
        # Jekyll.logger.warn("[PostFiles]", "mdfilepath:")
        # Jekyll.logger.warn("[PostFiles]", "#{mdfilepath}")
        # Jekyll.logger.warn("[PostFiles]", "post_path.to_path:")
        # Jekyll.logger.warn("[PostFiles]", "#{post_path.to_path}")
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

    # _posts/
    #   2018-01-01-whatever.md
    #   my-cool-post/
    #     2016-06-09-the-post.md
    #     cloudflare-architecture.png
    #     performance-report-sample.pdf
    # Generate content by copying files associated with each post.
    #
    # the working set (site.posts.docs) is proposed by:
    # jekyll/lib/jekyll/readers/post_reader.rb#read_posts
    #
    # only documents matching Document::DATE_FILENAME_MATCHER are accepted.
    # 
    # post_reader does not intend to support nesting, but accidentally
    # includes files under any directory whose name matches DATE_FILENAME_MATCHER
    #
    # we'll work around this by restoring the world to a ground truth:
    # 
    def generate(site)
      # site.posts.docs.each do |post|
      #   copy_post_files(post)
      # end

      site_src_dir = Pathname.new site.source
      posts_src_dir = site_src_dir + '_posts'
      drafts_src_dir = site_src_dir + '_drafts'

      Jekyll.logger.warn("[PostFiles]", "_posts: #{posts_src_dir}")
      Jekyll.logger.warn("[PostFiles]", "docs: #{site.posts.docs.map(&:path)}")

      # # Reject any .md nested deeper than _posts/dir/post.md
      # site.posts.docs.reject!{ |doc|
      #   Pathname.new(doc.path).relative_path_from(posts_src_dir).each_filename.count > 2
      # }

      # markdowns, assets = site.posts.docs.partition{ |doc|
      #   ['.md', '.markdown'].include?(Pathname.new(doc.path).extname)
      # }

      # # reject assets; they are not renderable documents
      # site.posts.docs = markdowns

      # Jekyll.logger.warn("[PostFiles]", "assets: #{assets.map(&:path)}")
      # Jekyll.logger.warn("[PostFiles]", "docs: #{site.posts.docs.map(&:path)}")

      docs_with_dirs = site.posts.docs
        .reject{ |doc| Pathname.new(doc.path).dirname.eql? posts_src_dir }

      Jekyll.logger.warn("[PostFiles]", "docs_with_dirs: #{docs_with_dirs.map{|doc| Pathname.new(doc.path).dirname}}")

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

      # any directory deeper than _posts containing multiple .md?
      # dirs_with_multi_md = site.posts.docs
      #   .map{ |doc| Pathname.new doc.path }
      #   .reject{ |path| path.dirname.eql? posts_src_dir }
      #   .group_by(&:dirname)
      #   .select{ |key,value| value.count > 1 }

      # if (dirs_with_multi_md.any?)
      #   Jekyll.logger.abort_with(
      #     "[PostFiles]",
      #     "Sorry, there can be only one Markdown file in each directory containing other assets to be copied by jekyll-postfiles. Violations: #{dirs_with_multi_md.map{ |key,value| [key.to_s, value.map(&:to_s)] }.to_h}"
      #   )
      # end

      # Jekyll.logger.abort_with(
      #   "[PostFiles]",
      #   "don't panic"
      # )

      # markdowns
      #   .map{ |doc| Pathname.new(doc.path) }
      #   .select{ |path|
      #     path.relative_path_from(posts_src_dir).each_filename.count == 2
      #   }

      # Pathname.new('/Users/birch/Documents/tmp').relative_path_from(Pathname.new('/Users/birch')).each_filename.count
    end
  end

end
