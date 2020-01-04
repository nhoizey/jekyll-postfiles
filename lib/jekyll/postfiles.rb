# frozen_string_literal: true

require "jekyll"
require "pathname"

module Jekyll
  module PostFiles

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
    Hooks.register :site, :after_reset do |_site|
      # Suppress warning messages.
      original_verbose = $VERBOSE
      $VERBOSE = nil
      Document.const_set("DATE_FILENAME_MATCHER", PostFileGenerator::FIXED_DATE_FILENAME_MATCHER)
      # Activate warning messages again.
      $VERBOSE = original_verbose
    end

    class PostFile < StaticFile
      # Initialize a new PostFile.
      #
      # site - The Site.
      # base - The String path to the <source> - /srv/jekyll
      # dir  - The String path between <source> and the file - _posts/somedir
      # name - The String filename of the file - cool.svg
      # dest - The String path to the containing folder of the document which is output - /dist/blog/[:tag/]*:year/:month/:day
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
      def destination(_dest)
        File.join(@dest, @name)
      end
    end

    class PostFileGenerator < Generator
      FIXED_DATE_FILENAME_MATCHER = %r!^(?:.+/)*(\d{2,4}-\d{1,2}-\d{1,2})-([^/]*)(\.[^.]+)$!.freeze

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
        site_srcroot = Pathname.new site.source

        # Jekyll.logger.warn("[PostFiles]", "_posts: #{posts_src_dir}")
        # Jekyll.logger.warn("[PostFiles]", "docs: #{site.posts.docs.map(&:path)}")

        # Jekyll.logger.warn("[PostFiles]", "postdirs: #{docs_with_dirs.map{|doc| Pathname.new(doc.path).dirname}}")

        config = site.config["postfiles"] || Hash.new()
        force_dir = config["force_dir"]

        docs = docs_with_dirs(site)
        docs_paths = docs.map(&:path)
        assets = docs.map do |doc|
          document_force_subdir(doc) if force_dir

          dest_dir = Pathname.new(doc.destination("")).dirname
          Pathname.new(doc.path).dirname.instance_eval do |postdir|
            # TODO maybe remove FIXED_DATE_FILENAME_MATCHER check
            Dir[postdir + "**/*"]
              .reject { |fname| fname =~ FIXED_DATE_FILENAME_MATCHER }
              .reject { |fname| File.directory? fname }
              .reject { |fname| docs_paths.include?(fname) }
              .map do |fname|
                asset_abspath = Pathname.new fname
                srcroot_to_asset = asset_abspath.relative_path_from(site_srcroot)
                srcroot_to_assetdir = srcroot_to_asset.dirname
                asset_basename = srcroot_to_asset.basename
                assetdir_abs = site_srcroot + srcroot_to_assetdir

                postdir_to_assetdir = assetdir_abs.relative_path_from(postdir)
                PostFile.new(
                  site, site_srcroot, srcroot_to_assetdir.to_path,
                  asset_basename, (dest_dir + postdir_to_assetdir).to_path)
              end
          end
        end.flatten

        site.static_files.concat(assets)
      end

      # determine whether file at path is a postfile path.
      # @param [String] path should be a relative path from the collection
      #                 directory to the file in question.
      def self.is_postfile?(file_path)
        File.dirname(file_path).delete_suffix('/').count('/') > 0
      end

      private

      def docs_with_dirs(site)
        site.collections.values.map do |collection|
          collection.docs.reject(&:draft?).select do |doc|
            self.class.is_postfile?(doc.relative_path)
          end
        end.flatten
      end

      # force the documents permalink to be within a subdirectory.
      def document_force_subdir(doc)
        col_permalink = doc&.collection&.metadata&.dig("permalink")
        replace_permalink = if doc.permalink
                              doc.permalink if !doc.permalink.end_with?("/")
                            elsif col_permalink
                              col_permalink if !col_permalink.end_with?("/")
                            end

        if replace_permalink
          doc.data["permalink"] = File.join(
            File.dirname(replace_permalink),
            replace_permalink.split('/')[-1].delete_suffix(":output_ext") + '/')
        end
      end
    end

    # even when we include a post files from a directory in the jekyll build
    # the collection still generates a StaticFile instance for the post file.
    # meaning we end up with the same files in both the same directory as the
    # posts permalink and it's original directory.
    #
    # NOTE maybe it'd be better to find the static file and change it's
    #      permalink, rather than creating a PostFile instance referencing
    #      the same file and then hiding that file here.
    module CollectionExcludePostFiles
      def read_static_file(file_path, full_path)
        relative_path = File.join(relative_directory, file_path)
        super unless PostFileGenerator.is_postfile?(relative_path)
      end
    end

    Collection.prepend(CollectionExcludePostFiles)
  end
end
