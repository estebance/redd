require_relative "../../objects/base"
require_relative "../../objects/thing"
require_relative "../../objects/listing"
require_relative "../../objects/wiki_page"
require_relative "../../objects/labeled_multi"
require_relative "../../objects/more_comments"
require_relative "../../objects/comment"
require_relative "../../objects/user"
require_relative "../../objects/submission"
require_relative "../../objects/private_message"
require_relative "../../objects/subreddit"

module Redd
  module Clients
    class Base
      # Internal methods that make life easier.
      # @todo Move this out to Redd::Utils?
      module Utilities
        # The kind strings and the objects that should be used for them.
        OBJECT_KINDS = {
          "Listing"      => Objects::Listing,
          "wikipage"     => Objects::WikiPage,
          "LabeledMulti" => Objects::LabeledMulti,
          "more"         => Objects::MoreComments,
          "t1"           => Objects::Comment,
          "t2"           => Objects::User,
          "t3"           => Objects::Submission,
          "t4"           => Objects::PrivateMessage,
          "t5"           => Objects::Subreddit
        }

        # Request and create an object from the response.
        # @param [Symbol] meth The method to use.
        # @param [String] path The path to visit.
        # @param [Hash] params The data to send with the request.
        # @return [Objects::Base] The object returned from the request.
        def request_object(meth, path, params = {})
          body = send(meth, path, params).body
          object_from_body(body)
        end

        # Create an object instance with the correct attributes when given a
        # body.
        #
        # @param [Hash] body A JSON hash.
        # @return [Objects::Thing, Objects::Listing]
        def object_from_body(body)
          return nil unless body.is_a?(Hash)
          object = object_from_kind(body[:kind])
          flat = flatten_body(body)
          object.new(self, flat)
        end

        # @param [Objects::Submission, Objects::Comment] base The start of the
        #   comment tree.
        # @author Bryce Boe (@bboe) in Python
        # @return [Array<Objects::Comment, Objects::MoreComments>] A linear
        #   array of the submission's comments or the comments' replies.
        def flat_comments(base)
          meth = (base.is_a?(Objects::Submission) ? :comments : :replies)
          stack = base.send(meth).dup
          flattened = []

          until stack.empty?
            comment = stack.shift
            if comment.is_a?(Objects::Comment)
              replies = comment.replies
              stack = replies + stack if replies
            end
            flattened << comment
          end

          flattened
        end

        # Get a given property of a given object.
        # @param [Objects::Base, String] object The object with the property.
        # @param [Symbol] property The property to get.
        def property(object, property)
          object.respond_to?(property) ? object.send(property) : object.to_s
        end

        private

        # Take a multilevel body ({kind: "tx", data: {...}}) and flatten it
        # into something like {kind: "tx", ...}
        # @param [Hash] body The response body.
        # @return [Hash] The flattened hash.
        def flatten_body(body)
          data = body[:data] || body
          data[:kind] = body[:kind]
          data
        end

        # @param [String] kind A kind in the format /t[1-5]/.
        # @return [Objects::Base, Objects::Listing] The appropriate object for
        #   a given kind.
        def object_from_kind(kind)
          OBJECT_KINDS.fetch(kind, Objects::Base)
        end
      end
    end
  end
end
