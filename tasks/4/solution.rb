RSpec.describe 'Version' do
  def v(version_string = nil)
    Version.new(version_string)
  end

  describe '.new' do
    it 'version can be created with valid arguments' do
      expect { v('1.2.3')       }.not_to raise_error
      expect { v('')            }.not_to raise_error
      expect { v(v('1.2.4343')) }.not_to raise_error
      expect { v('12.432.6')    }.not_to raise_error
      expect { Version.new      }.not_to raise_error
      expect { v('0.1.1')       }.not_to raise_error
    end

    it 'raises argument error on invalid arguments' do
      expect_to_raise_argument_error { v('a.2.4') }
      expect_to_raise_argument_error { v('1..4') }
      expect_to_raise_argument_error { v('1..4') }
      expect_to_raise_argument_error { v('5.2.') }
      expect_to_raise_argument_error { v('.2.6') }
    end

    it 'raises error with the rigth message' do
      expet_to_raise_with_right_message('a.2.4') { v('a.2.4') }
      expet_to_raise_with_right_message('1..4')  { v('1..4') }
      expet_to_raise_with_right_message('1..4')  { v('1..4') }
      expet_to_raise_with_right_message('5.2.')  { v('5.2.') }
      expet_to_raise_with_right_message('.2.6')  { v('.2.6') }
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
      expect(Version).to respond_to :<
      expect(Version).to respond_to :>
      expect(Version).to respond_to :<=
      expect(Version).to respond_to :>=
      expect(Version).to respond_to :==
      expect(Version).to respond_to :<=>
    end

    it 'can compare versions properly' do
      expect(v('3.2.1')     ).to be <   v('3.2.2')
      expect(v('4.5.2')     ).to be ==  v('4.5.2.0')
      expect(v('4.6.3')     ).to be <=  v('5.4.3')
      expect(v('4.5.2323')  ).to be >   v('4.5.2300')
      expect(v('123.2.4524')).to be >=  v('123.2.1')

      expect(v('4.5.2323') <=> v('4.5.23002')).to be(-1)

      expect(v('0')    ).to_not be > v('0.0.1')
      expect(v('1.0.1')).to_not be < v('1')

      expect(v('1.24')).to be >= v('1.23')
      expect(v('1.22')).to be >= v('1.22')
      expect(v('1.24')).to_not be >= v('1.25')

      expect(v('1.22')).to be <= v('1.23')
      expect(v('1.24')).to be <= v('1.24')
      expect(v('1.23')).to_not be <= v('1.21')
    end

    it 'can compare versions with different length' do
      expect(v('3.2.0')  ).to be < v('5.2')
      expect(v('4.5.0')  ).to be == v('4.5')
      expect(v('4.0.0.0')).to be < v('4.5')
      expect(v('4.5.1.0')).to be > v('4.5.0')
      expect(v('4.2.1.2')).to be > v('4.2')
    end

    it 'zero in the end is ignored' do
      expect(v('3.2.0')  ).to be < v('5.2.5')
      expect(v('4.5.0')  ).to be == v('4.5')
      expect(v('4.0.0.0')).to be < v('4.5')
      expect(v('4.5.1.0')).to be > v('4.5.0')
      expect(v('4.2')    ).to be == v('4.2.0')
    end
  end

  describe '#to_s' do
    it 'returns the right string' do
      expect(v('1.2.3').to_s ).to eq('1.2.3')
      expect(v('334').to_s   ).to eq('334')
      expect(v('0.3.23').to_s).to eq('0.3.23')
      expect(Version.new.to_s).to eq('')
      expect(v('').to_s      ).to eq('')
    end
  end

  describe '#components' do
    it 'returns the components in the correct order' do
      expect(v('1.3.5'    ).components).to eq([1, 3, 5])
      expect(v('1.9.3.7.2').components).to eq([1, 9, 3, 7, 2])
      expect(v('5.4.3.2'  ).components).to eq([5, 4, 3, 2])
    end

    it 'returns empty list for version zero' do
      expect(Version.new.components).to eq([])
      expect(v('').components).to eq([])
    end

    it 'skips zeros in the end' do
      expect(v('1.1.0'    ).components).to match_array([1, 1])
      expect(v('5.2.0.0.0').components).to match_array([5, 2])
    end

    it 'does not skip zeros that are not in the end' do
      expect(v('0.1.1'  ).components).to match_array([0, 1, 1])
      expect(v('0.0.1.1').components).to match_array([0, 0, 1, 1])
      expect(v('0.1.0.1').components).to match_array([0, 1, 0, 1])
    end

    it 'takes an optional argument' do
      expect { v('1.1.1').components(2) }.not_to raise_error
    end

    it 'return the given number of components' do
      expect(v('1.1.1'    ).components(2)).to match_array([1, 1])
      expect(v('1.1.1.5.3').components(3)).to match_array([1, 1, 1])
    end

    it 'fills the missing numbers with zeros' do
      expect(v('1.1.1').components(5)).to match_array([1, 1, 1, 0, 0])
      expect(v('4'    ).components(3)).to match_array([4, 0, 0])
    end

    it 'does not modify the version inside' do
      expect(Version.method_defined?(:components=)).to be(false)

      version = v('3.4.2')
      version.components(3)[0] = 5
      version.components[0] = 2
      expect(version.components).to match_array([3, 4, 2])
    end
  end

  describe 'Version::Range' do
    describe ".new" do
      it 'can be created with valid versions' do
        v1 = v('1.2.3')
        v2 = v('1.5.2')
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
        range = r('1', '1.5.1')
        expect(range).to include v('1.5.0.1.2')
        expect(range).to include v('1')
        expect(range).to include v('1.4.4985')
      end

      it 'returns false for version not in range' do
        range = r('1.2.3', '1.5.1')
        expect(range).not_to include v('1.5.1')
        expect(range).not_to include v('1.2.2')
      end

      it 'can take string as and argument' do
        range = r('1.2.3', '1.5.1')
        expect(range).not_to include '1.5.1'
        expect(range).to include '1.3'
      end
    end

    describe "#to_a" do
      it 'includes the first version' do
        range = r('1.2.3', '1.3')
        expect(range.to_a).to include '1.2.3'
      end

      it 'does not include the last version' do
        range = r('1.2.3', '1.3')
        expect(range.to_a).not_to include '1.3'
      end

      it 'includes all the versions in the range' do
        range = r('1.2.3', '1.2.6')
        expect(range.to_a).to eq(
          [
            v('1.2.3'),
            v('1.2.4'),
            v('1.2.5')
          ]
        )
      end

      it 'starts to count from the third component' do
        range = r('1.2.3.4', '1.2.6.1')
        expect(range.to_a).to eq(
          [
            v('1.2.3.4'),
            v('1.2.4'),
            v('1.2.5'),
            v('1.2.6')
          ]
        )
      end
    end

    def r(lower_bound, upper_bound)
      Version::Range.new(lower_bound, upper_bound)
    end
  end
end