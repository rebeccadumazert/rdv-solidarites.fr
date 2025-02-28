# frozen_string_literal: true

describe RdvsHelper do
  let(:motif) { build(:motif, name: "Consultation normale") }
  let(:user) { build(:user, first_name: "Marie", last_name: "DENIS") }
  let(:rdv) { build(:rdv, users: [user], motif: motif) }

  describe "#rdv_title_for_agent" do
    subject { helper.rdv_title_for_agent(rdv) }

    it { is_expected.to eq "Marie DENIS" }

    context "multiple users" do
      let(:user2) { build(:user, first_name: "Lea", last_name: "CAVE") }
      let(:rdv) { build(:rdv, users: [user, user2], motif: motif) }

      it { is_expected.to eq "Marie DENIS et Lea CAVE" }
    end

    context "created by user (reservable_online)" do
      let(:rdv) { build(:rdv, users: [user], motif: motif, created_by: :user) }

      it { is_expected.to eq "@ Marie DENIS" }
    end

    context "phone RDV" do
      let(:rdv) { build(:rdv, :by_phone, users: [user]) }

      it { is_expected.to eq "Marie DENIS ☎️" }
    end

    context "at home RDV" do
      let(:rdv) { build(:rdv, :at_home, users: [user]) }

      it { is_expected.to eq "Marie DENIS 🏠" }
    end
  end

  describe "#rdv_title" do
    it "show date, time and duration in minutes" do
      rdv = build(:rdv, starts_at: Time.zone.parse("2020-10-23 12h54"), duration_in_min: 30)
      expect(rdv_title(rdv)).to eq("Le vendredi 23 octobre 2020 à 12h54 (durée : 30 minutes)")
    end

    it "when rdv starts_at today, show only time and duration in minutes" do
      now = Time.zone.parse("2020-10-23 12h54")
      travel_to(now)
      rdv = build(:rdv, starts_at: now + 3.hours, duration_in_min: 30)
      expect(rdv_title(rdv)).to eq("Aujourd’hui à 15h54 (durée : 30 minutes)")
      travel_back
    end
  end

  describe "#rdv_starts_at_and_duration" do
    context "with :human format" do
      it "return starts_at hour, minutes and duration" do
        rdv = build(:rdv, starts_at: DateTime.new(2020, 3, 23, 12, 46), duration_in_min: 4)
        expect(rdv_starts_at_and_duration(rdv, :human)).to eq("lundi 23 mars 2020 à 13h46 (4 minutes)")
      end

      it "return only starts_at hour, minutes when no duration_in_min" do
        rdv = build(:rdv, starts_at: DateTime.new(2020, 3, 23, 12, 46), duration_in_min: nil)
        expect(rdv_starts_at_and_duration(rdv, :human)).to eq("lundi 23 mars 2020 à 13h46")
      end
    end

    context "with :time_only format" do
      it "return starts_at hour, minutes and duration" do
        rdv = build(:rdv, starts_at: DateTime.new(2020, 3, 23, 12, 46), duration_in_min: 4)
        expect(rdv_starts_at_and_duration(rdv, :time_only)).to eq("13h46 (4 minutes)")
      end

      it "return only starts_at hour, minutes when no duration_in_min" do
        rdv = build(:rdv, starts_at: DateTime.new(2020, 3, 23, 12, 46), duration_in_min: nil)
        expect(rdv_starts_at_and_duration(rdv, :time_only)).to eq("13h46")
      end
    end
  end
end
