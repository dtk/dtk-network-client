module DTK::Network
  module Client
    class ModuleMock
      def self.versions(dependency)
        name      = dependency[:name]
        namespace = dependency[:namespace]
        dependency[:versions] = VersionsHash["#{namespace}--#{name}"]
        if requirements = dependency[:requirements]
          if requirements.eql?('=')
            version = dependency[:version]
            dependency[:versions] = dependency[:versions].select { |v| v.eql?(version) }
          end
        end
        dependency
      end
      VersionsHash = {
        'test--uglifier' => ['0.0.8', "0.0.9", '1.0.0'],
        'test--multi_json' => ['1.1.1', "1.1.5", '1.1.7'],
        'test--execjs' => ['0.0.4', "1.1.5", '1.1.7'],
        'dtk-examples--concat' => ['1.1.1', '1.2.0', '1.2.2', '1.2.3'],
        'dtk-examples--wget' => ['1.0.0', '1.0.1', '1.1.0', '1.1.1'],
        'puppetlabs--postgresql' => ['1.2.0', '1.2.1', '1.2.2', '1.2.3'],
        'dtk-examples--dep1' => ['1.1.1', '1.2.1', '1.2.2', '1.2.3'],
        'puppetlabs--dep2' => ['1.1.1', '1.2.1', '1.2.2', '1.2.3'],
      }

      def self.ret(module_ref)
        MockHash["#{module_ref[:name]}--#{module_ref[:version]}".to_sym]
      end
      MockHash = {
        "execjs--0.0.4": {
          name: "multi_json",
          namespace: "test",
          version: "1.1.7",
          dependencies: []
        },
        "multi_json--1.1.7": {
          name: "multi_json",
          namespace: "test",
          version: "1.1.7",
          dependencies: []
        },
        "multi_json--1.1.5": {
          name: "multi_json",
          namespace: "test",
          version: "1.1.5",
          dependencies: []
        },
        "multi_json--1.1.1": {
          name: "multi_json",
          namespace: "test",
          version: "1.1.1",
          dependencies: []
        },
        "test--1.0.0": {
          name: "test",
          namespace: "test",
          version: "1.0.0",
          dependencies: [
            {
              name: 'multi_json',
              namespace: 'test',
              version: '1.1.1',
              requirements: '='
            },
            {
              name: 'uglifier',
              namespace: 'test',
              version: '0.0.0',
              requirements: 'any'
            }
          ]
        },
        "uglifier--0.0.8": {
          name: 'uglifier',
          namespace: 'test',
          version: '0.0.8',
          dependencies: [
            {
              name: 'execjs',
              namespace: 'test',
              version: '0.0.4',
              requirements: '='
            },
            {
              name: 'multi_json',
              namespace: 'test',
              version: '1.1.1',
              requirements: '='
            }
          ]
        },
        "uglifier--0.0.9": {
          name: 'uglifier',
          namespace: 'test',
          version: '0.0.9',
          dependencies: [
            {
              name: 'execjs',
              namespace: 'test',
              version: '0.0.4',
              requirements: '='
            },
            {
              name: 'multi_json',
              namespace: 'test',
              version: '1.1.1',
              requirements: '='
            }
          ]
        },
        "uglifier--1.0.0": {
          name: 'uglifier',
          namespace: 'test',
          version: '1.0.0',
          dependencies: [
            {
              name: 'execjs',
              namespace: 'test',
              version: '0.0.4',
              requirements: '='
            },
            {
              name: 'multi_json',
              namespace: 'test',
              version: '1.1.7',
              requirements: '='
            }
          ]
        },
        wordpress: {
          name: 'wordpress',
          namespace: 'dtk-examples',
          version: '1.0.0',
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

