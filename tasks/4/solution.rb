RSpec.describe 'Version' do
  describe '.new' do
    it 'version can be created with valid arguments' do
      expect { Version.new('1.2.3') }.not_to raise_error
      expect { Version.new('') }.not_to raise_error
      expect { Version.new Version.new('1.2.4343') }.not_to raise_error
      expect { Version.new('12.432.6') }.not_to raise_error
      expect { Version.new }.not_to raise_error
      expect { Version.new('0.1.1') }.not_to raise_error
    end

    it 'raises argument error on invalid arguments' do
      expect_to_raise_argument_error { Version.new('a.2.4') }
      expect_to_raise_argument_error { Version.new('1..4') }
      expect_to_raise_argument_error { Version.new('1..4') }
      expect_to_raise_argument_error { Version.new('5.2.') }
      expect_to_raise_argument_error { Version.new('.2.6') }
    end

    it 'raises error with the rigth message' do
      expet_to_raise_with_right_message('a.2.4') { Version.new('a.2.4') }
      expet_to_raise_with_right_message('1..4') { Version.new('1..4') }
      expet_to_raise_with_right_message('1..4') { Version.new('1..4') }
      expet_to_raise_with_right_message('5.2.') { Version.new('5.2.') }
      expet_to_raise_with_right_message('.2.6') { Version.new('.2.6') }
    end

    def expect_to_raise_argument_error(&block)
      expect(&block).to raise_error(ArgumentError)
    end

    def expet_to_raise_with_right_message(version_string, &block)
      expect(&block).to raise_error(
        ArgumentError, "Invalid version string '#{version_string}'"
      )
    end
  end
  describe 'comparison operators' do
    it 'has implemented comparison operators' do
      expect(Version.method_defined?(:<)).to be(true)
      expect(Version.method_defined?(:>)).to be(true)
      expect(Version.method_defined?(:<=)).to be(true)
      expect(Version.method_defined?(:>=)).to be(true)
      expect(Version.method_defined?(:==)).to be(true)
      expect(Version.method_defined?(:<=>)).to be(true)
    end

    it 'can compare versions properly' do
      expect(Version.new('3.2.1') < Version.new('3.2.2')).to be(true)
      expect(Version.new('4.5.2') == Version.new('4.5.2.0')).to be(true)
      expect(Version.new('4.6.3') <= Version.new('5.4.3')).to be(true)
      expect(Version.new('4.5.2323') > Version.new('4.5.2300')).to be(true)
      expect(Version.new('123.2.4524') >= Version.new('123.2.1')).to be(true)
      expect(Version.new('4.5.2323') <=> Version.new('4.5.23002')).to be(-1)
    end

    it 'can compare versions with different length' do
      expect(Version.new('3.2.0') < Version.new('5.2')).to be(true)
      expect(Version.new('4.5.0') == Version.new('4.5')).to be(true)
      expect(Version.new('4.0.0.0') < Version.new('4.5')).to be(true)
      expect(Version.new('4.5.1.0') > Version.new('4.5.0')).to be(true)
      expect(Version.new('4.2.1.2') > Version.new('4.2')).to be(true)
    end

    it 'zero in the end is ignored' do
      expect(Version.new('3.2.0') < Version.new('5.2.5')).to be(true)
      expect(Version.new('4.5.0') == Version.new('4.5')).to be(true)
      expect(Version.new('4.0.0.0') < Version.new('4.5')).to be(true)
      expect(Version.new('4.5.1.0') > Version.new('4.5.0')).to be(true)
      expect(Version.new('4.2') == Version.new('4.2.0')).to be(true)
    end
  end

  describe '#to_s' do
    it 'returns the right string' do
      expect(Version.new('1.2.3').to_s).to eq('1.2.3')
      expect(Version.new('334').to_s).to eq('334')
      expect(Version.new('0.3.23').to_s).to eq('0.3.23')
      expect(Version.new.to_s).to eq('')
      expect(Version.new('').to_s).to eq('')
      expect(Version.new.to_s).to eq('')
    end
  end

  describe '#components' do
    it 'returns the components in the correct order' do
      expect(Version.new('1.3.5').components).to eq([1, 3, 5])
      expect(Version.new('1.9.3.7.2').components).to eq([1, 9, 3, 7, 2])
      expect(Version.new('5.4.3.2').components).to eq([5, 4, 3, 2])
    end

    it 'returns empty list for version zero' do
      expect(Version.new.components).to eq([])
      expect(Version.new('').components).to eq([])
    end

    it 'skips zeros in the end' do
      expect(Version.new('1.1.0').components).to match_array([1, 1])
      expect(Version.new('5.2.0.0.0').components).to match_array([5, 2])
    end

    it 'does not skip zeros that are not in the end' do
      expect(Version.new('0.1.1').components).to match_array([0, 1, 1])
      expect(Version.new('0.0.1.1').components).to match_array([0, 0, 1, 1])
      expect(Version.new('0.1.0.1').components).to match_array([0, 1, 0, 1])
    end

    it 'takes an optional argument' do
      expect { Version.new('1.1.1').components(2) }.not_to raise_error
    end

    it 'return the given number of components' do
      expect(Version.new('1.1.1').components(2)).to match_array([1, 1])
      expect(Version.new('1.1.1.5.3').components(3)).to match_array([1, 1, 1])
    end

    it 'fills the missing numbers with zeros' do
      expect(Version.new('1.1.1').components(5)).to match_array([1, 1, 1, 0, 0])
      expect(Version.new('4').components(3)).to match_array([4, 0, 0])
    end

    it 'does not modify the version inside' do
      expect(Version.method_defined?(:components=)).to be(false)
      version = Version.new('3.4.2')
      version.components(3)[0] = 5
      expect(version.components).to match_array([3, 4, 2])
    end
  end

  describe 'Version::Range' do
    describe ".new" do
      it 'can be created with valid versions' do
        v1 = Version.new('1.2.3')
        v2 = Version.new('1.5.2')
        v3 = '2.1.8'
        v4 = '2.3.6'
        expect { Version::Range.new(v1, v2) }.not_to raise_error
        expect { Version::Range.new(v3, v4) }.not_to raise_error
        expect { Version::Range.new(v1, v3) }.not_to raise_error
        expect { Version::Range.new(v2, v4) }.not_to raise_error
      end
    end

    describe "#include?" do
      it 'returns true for versions in range' do
        range = create_range('1', '1.5.1')
        expect(range.include?(Version.new('1.5.0.1.2'))).to be(true)
        expect(range.include?(Version.new('1'))).to be(true)
        expect(range.include?(Version.new('1.4.4985'))).to be(true)
      end

      it 'returns false for version not in range' do
        range = create_range('1.2.3', '1.5.1')
        expect(range.include?(Version.new('1.5.1'))).to be(false)
        expect(range.include?(Version.new('1.2.2'))).to be(false)
      end

      it 'can take string as and argument' do
        range = create_range('1.2.3', '1.5.1')
        expect(range.include?('1.5.1')).to be(false)
        expect(range.include?('1.3')).to be(true)
      end
    end

    describe "#to_a" do
      it 'includes the first version' do
        range = create_range('1.2.3', '1.3')
        expect(range.to_a.include?('1.2.3')).to be(true)
      end

      it 'does not include the last version' do
        range = create_range('1.2.3', '1.3')
        expect(range.to_a.include?('1.3')).to be(false)
      end

      it 'includes all the versions in the range' do
        range = create_range('1.2.3', '1.2.6')
        expect(range.to_a).to eq(
          [
            Version.new('1.2.3'),
            Version.new('1.2.4'),
            Version.new('1.2.5')
          ]
        )
      end

      it 'starts to count from the third component' do
        range = create_range('1.2.3.4', '1.2.6.1')
        expect(range.to_a).to eq(
          [
            Version.new('1.2.3.4'),
            Version.new('1.2.4'),
            Version.new('1.2.5'),
            Version.new('1.2.6')
          ]
        )
      end
    end
    
    def create_range(lower_bound, upper_bound)
      Version::Range.new(lower_bound, upper_bound)
    end
  end
end