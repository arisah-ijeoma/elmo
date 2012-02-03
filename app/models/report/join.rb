class Report::Join
  
  attr_reader :name, :sql, :dependencies

  def self.list_to_sql(list)
    expanded = []
    list.each{|j| expanded += @@joins[j.to_sym].expand}
    expanded = expanded.flatten.uniq
    expanded.collect{|join| join.sql}
  end
  
  def initialize(params)
    @sql = params[:sql]
    @name = params[:name]
    @dependencies = params[:dependencies] ? (params[:dependencies].is_a?(Symbol) ? [params[:dependencies]] : params[:dependencies]) : []
  end

  def expand
    (dependencies ? dependencies.collect{|dep| @@joins[dep].expand}.flatten : []) + [self]
  end
  
  @@joins = {
    :answers => new(
      :name => :answers,
      :sql => "LEFT OUTER JOIN answers ON answers.response_id = responses.id"
    ),
    :questionings => new(
      :dependencies => :answers,
      :name => :questionings, 
      :sql => "INNER JOIN questionings ON answers.questioning_id = questionings.id"
    ),      
    :options => new(
      :dependencies => :answers,
      :name => :options,
      :sql => ["LEFT JOIN options ao ON answers.option_id = ao.id",
        "LEFT JOIN translations aotr ON (aotr.obj_id = ao.id and aotr.fld = 'name' and aotr.class_name = 'Option' " +
          "AND aotr.language_id = (SELECT id FROM languages WHERE code = 'eng'))"]
    ),      
    :choices => new(
      :dependencies => :answers,
      :name => :choices,
      :sql => ["LEFT JOIN choices ON choices.answer_id = answers.id",
        "LEFT JOIN options co ON choices.option_id = co.id",
        "LEFT JOIN translations cotr ON (cotr.obj_id = co.id and cotr.fld = 'name' and cotr.class_name = 'Option' " + 
            "AND cotr.language_id = (SELECT id FROM languages WHERE code = 'eng'))"]
    ),      
    :forms => new(
      :name => :forms,
      :sql => "INNER JOIN forms ON responses.form_id = forms.id"
    ),      
    :form_types => new(
      :name => :form_types,
      :dependencies => :forms, 
      :sql => "INNER JOIN form_types ON forms.form_type_id = form_types.id"
    ),      
    :questions => new(
      :name => :questions,
      :dependencies => :questionings,
      :sql => "INNER JOIN questions ON questionings.question_id = questions.id"
    ),      
    :question_types => new( 
      :name => :question_types,
      :dependencies => :questions, 
      :sql => "INNER JOIN question_types ON questions.question_type_id = question_types.id"
    ),      
    :places => new(
      :name => :places, 
      :sql => "LEFT JOIN places ON responses.place_id = places.id"
    ),
    :place_types => new(
      :name => :place_types,
      :dependencies => :places,
      :sql => "LEFT JOIN place_types ON places.place_type_id = place_types.id"
    ),
    :localities => new(
      :name => :localities,
      :dependencies => :place_types, 
      :sql => "LEFT JOIN places localities ON IF(place_types.short_name = 'locality', places.id, places.locality_id) = localities.id"
    ),
    :states => new(
      :name => :states,
      :dependencies => :place_types, 
      :sql => "LEFT JOIN places states ON IF(place_types.short_name = 'state', places.id, places.state_id) = states.id"
    ),
    :countries => new(
      :name => :countries,
      :dependencies => :place_types, 
      :sql => "LEFT JOIN places countries ON IF(place_types.short_name = 'country', places.id, places.country_id) = countries.id"
    )
  }       
end         