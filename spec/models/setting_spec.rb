require 'spec_helper'

describe Setting do
  it_behaves_like "has a uuid"

  let(:setting) { get_mission.setting }

  it "serialized locales are always symbols" do
    expect(setting.preferred_locales.first.class).to eq(Symbol)
    setting.update_attributes!(preferred_locales_str: "fr,ar")
    expect(setting.preferred_locales.first.class).to eq(Symbol)
  end

  it "locales with spaces should still be accepted" do
    setting.update_attributes!(preferred_locales_str: "fr , ar1")
    expect(setting.preferred_locales).to eq([:fr, :ar])
  end

  it "generate override code will generate a new six character code" do
    previous_code = setting.override_code
    setting.generate_override_code!
    expect(previous_code).not_to eq(setting.override_code)
    expect(setting.override_code.size).to eq(6)
  end

  describe 'load_for_mission' do
    shared_examples_for 'load_for_mission' do
      context 'when there are no existing settings' do
        before do
          Setting.load_for_mission(mission).destroy
        end

        it 'should create one with default values' do
          setting = Setting.load_for_mission(mission)
          expect(setting.new_record?).to be_falsey
          expect(setting.mission).to eq mission
          expect(setting.timezone).to eq Setting::DEFAULT_TIMEZONE
        end
      end

      context 'when a setting exists' do
        before { Setting.load_for_mission(mission).update_attributes!(:preferred_locales => [:fr]) }

        it 'should load it' do
          setting = Setting.load_for_mission(mission)
          expect(setting.preferred_locales).to eq [:fr]
        end

        after do
          I18n.locale = :en
        end
      end
    end

    context 'for null mission' do
      let(:mission) { nil }
      it_should_behave_like 'load_for_mission'

      it 'should not have an incoming_sms_token', :sms do
        setting = Setting.load_for_mission(mission)
        expect(setting.incoming_sms_token).to be_nil
      end
    end

    context 'for mission' do
      let(:mission) { get_mission }
      it_should_behave_like 'load_for_mission'

      it 'should have an incoming_sms_token', :sms do
        setting = Setting.load_for_mission(mission)
        expect(setting.incoming_sms_token).to match(/\A[0-9a-f]{32}\z/)
      end

      it 'should have the same incoming_sms_token after reloading', :sms do
        setting = Setting.load_for_mission(mission)
        token = setting.incoming_sms_token

        setting.reload

        expect(setting.incoming_sms_token).to eq(token)
      end

      it 'should have a different incoming_sms_token after calling regenerate_incoming_sms_token!', :sms do
        setting = Setting.load_for_mission(mission)
        token = setting.incoming_sms_token

        setting.regenerate_incoming_sms_token!

        expect(setting.incoming_sms_token).not_to eq(token)
      end

      it 'should normalize the twilio_phone_number on save', :sms do
        setting = Setting.load_for_mission(mission)
        setting.twilio_phone_number = "+1 770 555 1212"
        setting.twilio_account_sid = "AC0000000"
        setting.twilio_auth_token = "ABCDefgh1234"
        setting.save!
        expect(setting.twilio_phone_number).to eq("+17705551212")
      end
    end
  end
end
