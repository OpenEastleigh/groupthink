# frozen_string_literal: true

require "rails_helper"

RSpec.describe Proposal do
  context "checking overall state" do
    it "stores merged pull requests as accepted" do
      # stub state indicators
      allow_any_instance_of(described_class).to receive(:pr_closed?).and_return(true)
      allow_any_instance_of(described_class).to receive(:pr_merged?).and_return(true)
      # Test
      pr = create :proposal
      pr.update_state!
      expect(pr.state).to eq "accepted"
    end

    it "stores closed and unmerged pull requests as rejected", :vcr do
      # stub state indicators
      allow_any_instance_of(described_class).to receive(:pr_closed?).and_return(true)
      allow_any_instance_of(described_class).to receive(:pr_merged?).and_return(false)
      # Test
      pr = create :proposal
      pr.update_state!
      expect(pr.state).to eq "rejected"
    end
  end

  context "notification of new proposals" do
    before :all do
      @proposer = create :user, contributor: true, notify_new: true
      @voter = create :user, contributor: true, notify_new: true
      @no_notifications = create :user, contributor: true, notify_new: false
      @participant = create :user, contributor: false, notify_new: true
    end

    before do
      @mail = double("mail")
      allow(@mail).to receive(:deliver_later)
    end

    it "goes to voters" do
      expect(ProposalsMailer).to receive(:new_proposal).once do |user, proposal|
        expect(user).to eql @voter
        expect(proposal).to be_valid
        @mail
      end
      create :proposal, proposer: @proposer
    end

    it "does not go to proposer" do
      expect(ProposalsMailer).to receive(:new_proposal).at_least(:once) do |user, proposal|
        expect(user).not_to eql @proposer
        expect(proposal).to be_valid
        @mail
      end
      create :proposal, proposer: @proposer
    end

    it "does not go to a voter who has turned off notifications" do
      expect(ProposalsMailer).to receive(:new_proposal).at_least(:once) do |user, proposal|
        expect(user).not_to eql @no_notifications
        expect(proposal).to be_valid
        @mail
      end
      create :proposal, proposer: @proposer
    end

    it "does not go to people who don't have the vote" do
      expect(ProposalsMailer).to receive(:new_proposal).at_least(:once) do |user, proposal|
        expect(user).not_to eql @participant
        expect(proposal).to be_valid
        @mail
      end
      create :proposal, proposer: @proposer
    end
  end
end
