class Vote < Vue
  def initialize
    @disabled = true
    @alert = nil

    # initialize form fields
    @user = Server.data.user
    @proposer = Server.data.proposer
    @pmc = Server.data.contributor[:project]
    @iclaname = Server.data.contributor[:name]
    @iclaemail = Server.data.contributor[:email]
    @token = Server.data.token
    @comments = Server.data.comments
    @votes = Server.data.votes
    @vote = ''
    @timestamp = ''
    @commentBody = ''
    @subject = Server.data.subject
    @showComment = true;
    @debug = false;

  end

  def render
    _p %{
      This form allows PMC and PPMC members to
      vote to invite a contributor to become a committer or a PMC/PPMC member.
    }
    _b "Project: " + @pmc
    _p
    _b "Contributor: " + @iclaname + " (" + @iclaemail + ")"
    _p
    _b "Proposed by: " + @proposer
    _p
    _p "Subject: " + @subject
    _p
    _div.form_group.vote do
      _label do
        _input type: 'radio', name: 'vote', value: '+1',
        onClick: -> {@vote = '+1'; @showComment = false; checkValidity()}
        _span " +1 approve "
      end
      _p
      _label do
        _input type: 'radio', name: 'vote', value: '+0',
        onClick: -> {@vote = '+0'; @showComment = false; checkValidity()}
        _span " +0 don't care "
      end
      _p
      _label do
        _input type: 'radio', name: 'vote', value: '-0',
        onClick: -> {@vote = '-0'; @showComment = false; checkValidity()}
        _span " -0 don't care "
      end
      _p
      _label do
        _input type: 'radio', name: 'vote', value: '-1',
        onClick: -> {@vote = '-1'; @showComment = true; checkValidity()}
        _span " -1 disapprove, because... "
      end
      _p
    end

    # error messages
    if @alert
      _div.alert.alert_danger do
        _b 'Error: '
        _span @alert
      end
    end

    #
    # Form fields
    #
    if @showComment
      _div.form_group do
        _textarea.form_control rows: 4,
        placeholder: 'reason to disapprove',
        id: 'commentBody', value: @commentBody,
        onChange: self.setCommentBody
      end
    end

    @votes.each {|v|
      _p v.vote + ' From: ' + v.member + ' Date: ' + v.timestamp
    }

    @comments.each {|c|
      _b 'From: ' + c.member + ' Date: ' + c.timestamp
      _p c.comment
    }

    if @debug
      _p 'token: ' + @token
      _p 'comment: ' + @commentBody
      _p 'vote: ' + @vote
    end


    #
    # Submission button
    #

    _p do
      _button.btn.btn_primary 'Submit my vote', disabled: @disabled,
        onClick: self.submitVote
      _b ' or '
      _button.btn.btn_primary 'Cancel the vote', disabled: @disabled,
        onClick: self.cancelVote
      _b ' or '
      _button.btn.btn_primary 'Tally the vote', disabled: @disabled,
        onClick: self.tallyVote
    end





    #
    # Hidden form: preview invite email
    #
    _div.modal.fade.invitation_preview! do
      _div.modal_dialog do
        _div.modal_content do
          _div.modal_header do
            _button.close "\u00d7", type: 'button', data_dismiss: 'modal'
            _h4 'Preview Invitation Email'
          end

          _div.modal_body do
            # headers
            _div do
              _b 'From: '
              _span @userEmail
            end
            _div do
              _b 'To: '
              _span "#{@iclaname} <#{@iclaemail}>"
            end
            _div do
              _b 'cc: '
              _span @pmcEmail
            end

            # draft invitation email
            _div.form_group do
              _label for: 'invitation'
              _textarea.form_control.invitation! value: @invitation, rows: 12,
                onChange: self.setInvitation
            end
          end

          _div.modal_footer do
            _button.btn.btn_default 'Cancel', data_dismiss: 'modal'
            _button.btn.btn_primary 'Mock Send', onClick: self.mockSend
          end
        end
      end
    end


  end

  # when the form is initially loaded, set the focus on the iclaname field
  def mounted()
    document.getElementById('commentBody').focus()
  end

  #
  # field setters
  #
  def setCommentBody(event)
    @commentBody = event.target.value
    checkValidity()
  end



  #
  # validation and processing
  #

  # client side field validations
  def checkValidity()
    # no vote or vote -1 without comment
    @disabled = (@vote == '' or (@vote == '-1' and @commentBody.empty?))
  end


  # server side field validations
  def previewInvitation()
    data = {
      iclaname: @iclaname,
      iclaemail: @iclaemail,
      pmc: @pmc,
      votelink: @votelink,
      noticelink: @noticelink
    }

    @disabled = true
    @alert = nil
    post 'validate', data do |response|
      @disabled = false
      @alert = response.error
      @userEmail = response.userEmail
      @pmcEmail = response.pmcEmail
      @invitation = response.invitation
      @token = response.token
      document.getElementById(response.focus).focus() if response.focus
      jQuery('#invitation-preview').modal(:show) unless @alert
    end
  end

  # pretend to send an invitation
  def mockSend()
    # dismiss modal dialog
    jQuery('#invitation-preview').modal(:hide)

    # save information for later use (for demo purposes, this is client only)
    FormData.token = @token
    FormData.fullname = @iclaname
    FormData.email = @iclaemail
    FormData.pmc = @pmc
    FormData.votelink = @votelink
    FormData.noticelink = @noticelink

    # for demo purposes advance to the interview.  Note: the below line
    # updates the URL in a way that breaks the back button.
    history.replaceState({}, nil, "form?token=#@token")

    # change the view
    Main.navigate(Interview)
  end
end
