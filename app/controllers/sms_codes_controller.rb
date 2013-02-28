class SmsCodesController < ApplicationController
  # TOM what is this? please don't leave commented code lying around like this
  # render :text => n, :status => 200
  def show
  	
  	# this may be different that the language setting for the website
  	I18n.locale = configatron.outgoing_sms_language
  	
  	# TOM be careful with style. space before the = sign is the usual convention.
  	@form_id= params[:form_id]
    get_codes
    
    # TOM you don't need the :template argument. please read the docs on Rails rendering.
    # TOM also why are you rendering with no layout? i'm confused about this.
    render :template => 'sms_codes/show.html', :layout => false
  end
 
  # TOM this definitely looks like model code. please read up on the MVC design pattern.
  def get_codes	
		
		@form = Form.find(@form_id)	
		
		# array to store qings to be printed 
		@sms_qings = {}
		
		# TOM space after #
		#resets last to nil;
		@last_qing_id = nil
		
		unless @form == nil	
			# get all the codes for this form
			# TOM should be using an association here. please read up on ActiveRecord associations.
			sms_codes = SmsCode.where('form_id = ? ', @form_id).order("question_number ASC, code ASC")
			sms_codes.each do |c|
			# TOM please be careful with indentation.
			unless sms_codes.empty?
					@qing = c.questioning
					
					# is this the next qing?
					# we test using the last_qing_id
					# TOM x ? true : false is equivalent to just x
					# TOM don't need parens on if condition
					if (@last_qing_id != @qing.id ? true : false)
						# array to temporarily store code text
						@code_text = []
						@last_qing_id = @qing.id					
					
					end
					
					if c.code != nil
					  # TOM should use string interpolation here. please read up on ruby string interpolation
						@code_text << c.code + '. ' + c.option.name
					end
					
					@sms_qings[@qing.id] = {:qing => @qing, :code_text => @code_text}
					
				end
			end
		end
	end

end