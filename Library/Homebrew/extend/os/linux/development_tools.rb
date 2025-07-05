# typed: strict
# frozen_string_literal: true

module OS
  module Linux
    module DevelopmentTools
      module ClassMethods
        extend T::Helpers

        requires_ancestor { ::DevelopmentTools }

        sig { params(tool: T.any(String, Symbol)).returns(T.nilable(Pathname)) }
        def locate(tool)
          @locate ||= T.let({}, T.nilable(T::Hash[T.any(String, Symbol), Pathname]))
          @locate.fetch(tool) do |key|
            @locate[key] = if ::DevelopmentTools.needs_build_formulae? &&
                              (binutils_path = HOMEBREW_PREFIX/"opt/binutils/bin/#{tool}").executable?
              binutils_path
            elsif ::DevelopmentTools.needs_build_formulae? &&
                  (glibc_path = HOMEBREW_PREFIX/"opt/glibc/bin/#{tool}").executable?
              glibc_path
            elsif (homebrew_path = HOMEBREW_PREFIX/"bin/#{tool}").executable?
              homebrew_path
            elsif File.executable?(system_path = "/usr/bin/#{tool}")
              Pathname.new system_path
            end
          end
        end

        sig { returns(Symbol) }
        def default_compiler = :gcc

        sig { returns(T::Boolean) }
        def needs_libc_formula?
          return @needs_libc_formula unless @needs_libc_formula.nil?

          @needs_libc_formula = T.let(OS::Linux::Glibc.below_ci_version?, T.nilable(T::Boolean))
          @needs_libc_formula = !!@needs_libc_formula
        end

        # Keep this method around for now to make it easier to add this functionality later.
        # rubocop:disable Lint/UselessMethodDefinition
        sig { returns(Pathname) }
        def host_gcc_path
          # TODO: override this if/when we to pick the GCC based on e.g. the Ubuntu version.
          super
        end
        # rubocop:enable Lint/UselessMethodDefinition

        sig { returns(T::Boolean) }
        def needs_compiler_formula?
          return @needs_compiler_formula unless @needs_compiler_formula.nil?

          @needs_compiler_formula = T.let(nil, T.nilable(T::Boolean))
          @needs_compiler_formula = if host_gcc_path.exist?
            ::DevelopmentTools.gcc_version(host_gcc_path.to_s) < OS::LINUX_GCC_CI_VERSION
          else
            true
          end
        end

        sig { returns(T::Hash[String, T.nilable(String)]) }
        def build_system_info
          super.merge({
            "glibc_version"     => OS::Linux::Glibc.version.to_s.presence,
            "oldest_cpu_family" => ::Hardware.oldest_cpu.to_s,
          })
        end
      end
    end
  end
end

DevelopmentTools.singleton_class.prepend(OS::Linux::DevelopmentTools::ClassMethods)
