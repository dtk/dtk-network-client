module DTK::Network
  module Client
    class ModuleMock
      def self.versions(dependency)
        name      = dependency[:name]
        namespace = dependency[:namespace]
        dependency[:versions] = VersionsHash["#{name}--#{namespace}"]
        dependency
      end
      VersionsHash = {
        'dtk-examples--concat' => ['1.1.1', '1.2.0', '1.2.2', '1.2.3'],
        'dtk-examples--wget' => ['1.0.0', '1.0.1', '1.1.0', '1.1.1'],
        'puppetlabs--postgresql' => ['1.2.0', '1.2.1', '1.2.2', '1.2.3'],
        'dtk-examples--dep1' => ['1.1.1', '1.2.1', '1.2.2', '1.2.3'],
        'dtk-examples--dep2' => ['1.1.1', '1.2.1', '1.2.2', '1.2.3'],
      }

      def self.ret(module_ref)
        MockHash[module_ref[:name]]
      end
      MockHash = {
        wordpress: {
          name: 'wordpress',
          namespace: 'dtk-examples',
          version: '1.0.0'
          dependencies: [
            {
              name: 'concat',
              namespace: 'dtk-examples',
              version: '1.2.3',
              requirements: '='
            },
            {
              name: 'wget',
              namespace: 'dtk-examples',
              version: '1.1.1',
              requirements: '~>'
            },
            {
              name: 'postgresql',
              namespace: 'puppetlabs',
              version: '1.2.3',
              requirements: '>='
            }
          ]
        },
        concat: {
          name: 'concat',
          namespace: 'dtk-examples',
          version: '1.2.3',
          dependencies: [
            {
              name: 'dep1',
              namespace: 'dtk-examples',
              version: '1.2.3',
              requirements: '='
            },
            {
              name: 'wget',
              namespace: 'dtk-examples',
              version: '1.1.2',
              requirements: '='
            },
            {
              name: 'dep2',
              namespace: 'puppetlabs',
              version: '1.2.3',
              requirements: '='
            }
          ]
        },
        wget: {
          name: 'wget',
          namespace: 'dtk-examples',
          version: '1.1.1',
          dependencies: [
            {
              name: 'dep1',
              namespace: 'dtk-examples',
              version: '1.2.3',
              requirements: '~>'
            },
            {
              name: 'dep2',
              namespace: 'puppetlabs',
              version: '1.2.3',
              requirements: '='
            }
          ]
        },
        postgresql: {
          name: 'postgresql',
          namespace: 'puppetlabs',
          version: '1.2.3',
          dependencies: [
            {
              name: 'dep1',
              namespace: 'dtk-examples',
              version: '1.2.2',
              requirements: '~>'
            },
            {
              name: 'wget',
              namespace: 'dtk-examples',
              version: '1.1.2',
              requirements: '='
            }
          ]
        },
        dep1: {
          name: 'dep1',
          namespace: 'dtk-examples',
          version: '1.2.3',
          dependencies: []
        },
        dep2: {
          name: 'dep2',
          namespace: 'puppetlabs',
          version: '1.2.3',
          dependencies: []
        }
      }
    end
  end
end

