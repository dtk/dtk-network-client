module DTK
  module Client
    module PermissionsUtil
      def validate_permissions!(permission_string)
        # matches example: u-rw, ugo+r, go+w
        match = permission_string.match(/^[ugo]+[+\-][rwd]+$/)
        raise Error.new("Provided permissions expression ('#{permission_string}') is not valid") unless match
        permission_string
      end
    end
  end
end