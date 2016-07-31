module VoteCounter
  extend ActiveSupport::Concern
  
  def sha
    @sha ||= github_pr.head.sha
  end
  
  def count_votes!
    process_comments
    update_state!
  end
    
  def update_state!
    if github_pr.state == "closed"
      if github_pr.merged == true
        state = "accepted"
      else
        state = "rejected"
      end
    else
      required_agrees = 2
      github_state = nil
      github_description = nil
      votes = agree.count - abstain.count
      if disagree.count > 0
        state = "blocked"
        github_state = "failure"
        github_description = "The change is blocked."
      elsif votes >= required_agrees
        state = "passed"
        github_state = "success"
        github_description = "The change is agreed."
      else
        state = "waiting"
        github_state = "pending"
        github_description = "The change is waiting for more votes; #{required_agrees - votes} more needed."
      end
      # Update github commit status
      Octokit.create_status(ENV['GITHUB_REPO'], sha, github_state,
        target_url: "http://votebot.openpolitics.org.uk/#{number}",
        description: github_description,
        context: "votebot/votes")
      # Check age
      if age >= 90
        state = "dead"
        github_state = "failure"
        github_description = "The change has been open for more than 90 days, and should be closed."
      elsif age >= 7
        github_state = "success"
        github_description = "The change has been open long enough to be merged."
      else
        state = "agreed" if state == "passed"
        github_state = "pending"
        github_description = "The change has not yet been open for 7 days."
      end
      # Update github commit status
      Octokit.create_status(ENV['GITHUB_REPO'], sha, github_state,
        target_url: "http://votebot.openpolitics.org.uk/#{number}",
        description: github_description,
        context: "votebot/time")
    end
    # Store final state in DB
    update_attributes!(state: state)
  end

  def process_comments
    comments = Octokit.issue_comments(ENV['GITHUB_REPO'], number)
    if sha
      commit = Octokit.pull_commits(ENV['GITHUB_REPO'], number).find{|x| x.sha == sha}
      cutoff = commit.commit.committer.date
    else
      cutoff = DateTime.new(1970)
    end
    comments.each do |comment|
      user = User.find_or_create_by(login: comment.user.login)
      if user != proposer
        interaction = interactions.find_or_create_by!(user: user)
        if user.contributor
          case comment.body
          when /:thumbsup:|:\+1:|👍/
            next if comment.created_at < cutoff
            interaction.agree!
          when /:hand:|✋/
            interaction.abstain!
          when /:thumbsdown:|:\-1:|👎/
            interaction.disagree!
          end
        end
      end
    end
  end

end