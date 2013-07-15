module ApplicationHelper
  
  FONT_AWESOME_ICON_MAPPINGS = {
    :clone => "copy",
    :destroy => "trash",
    :edit => "edit",
    :map => "globe",
    :print => "print",
    :publish => "arrow-up",
    :sms => "comment",
    :unpublish => "arrow-down"
  }
  
  # renders the flash message and any form errors for the given activerecord object
  def flash_and_form_errors(object = nil)
    render("layouts/flash", :flash => flash, :object => object)
  end
  
  # returns the html for an action icon using font awesome and the mappings defined above
  def action_link(action, href, html_options = {})
    # join passed html class (if any) with the default class
    html_options[:class] = [html_options[:class], "action_link"].compact.join(" ")
    
    link_to(content_tag(:i, "", :class => "icon-" + FONT_AWESOME_ICON_MAPPINGS[action.to_sym]), href, html_options)
  end
  
  # assembles links for the basic actions in an index table (show edit and destroy)
  def action_links(obj, options)
    route_key = obj.class.model_name.singular_route_key
    links = %w(edit destroy).collect do |action|
      options[:exclude] = [options[:exclude]] unless options[:exclude].is_a?(Array)
      next if options[:exclude] && options[:exclude].include?(action.to_sym)
      key = "#{obj.class.table_name}##{action}"
      case action
      when "edit"
        can?(:update, obj) ? action_link(action, send("edit_#{route_key}_path", obj), :title => t("common.edit")) : nil
      when "destroy"
        # build a delete warning
        obj_description = options[:obj_name] ? "#{obj.class.model_name.human} '#{options[:obj_name]}'" : options[:obj_description]
        warning = t("layout.delete_warning", :obj_description => obj_description)
        
        can?(:destroy, obj) ? action_link(action, send("#{route_key}_path", obj), :method => :delete, 
          :confirm => warning, :title => t("common.delete")) : nil
      end
    end.compact
    links.join("").html_safe
  end
  
  # creates a link to a batch operation
  def batch_op_link(options)
    button_to(options[:name], "#", 
      :onclick => "batch_submit({path: '#{options[:path]}', confirm: '#{options[:confirm]}'}); return false;",
      :class => "batch_op_link")
  end
  
  # creates a link to select all the checkboxes in an index table
  def select_all_link
    button_to(t("layout.select_all"), "#", :onclick => "batch_select_all(); return false", :id => "select_all_link")
  end
  
  # renders an index table for the given class and list of objects
  def index_table(klass, objects)
    # get links from class' helper
    links = send("#{klass.table_name}_index_links", objects).compact

    # if there are any batch links, insert the 'select all' link
    batch_ops = !links.reject{|l| !l.match(/class="batch_op_link"/)}.empty?
    links.insert(0, select_all_link) if batch_ops
    
    # render, getting fields and checking if there are no objects at all
    render("layouts/index_table",
      :klass => klass,
      :objects => objects,
      :paginated => objects.respond_to?(:total_entries),
      :links => links.flatten.join.html_safe,
      :fields => send("#{klass.table_name}_index_fields"),
      :batch_ops => batch_ops
    )
  end
  
  # renders a loading indicator image wrapped in a wrapper
  def loading_indicator(options = {})
    content_tag("div", :class => "loading_indicator loading_indicator#{options[:floating] ? '_floating' : '_inline'}", :id => options[:id]) do
      image_tag("load-ind-small#{options[:header] ? '-header' : ''}.gif", :style => "display: none", :id => "loading_indicator" + 
        (options[:id] ? "_#{options[:id]}" : ""))
    end
  end
  
  # returns a set of [name, id] pairs for the given objects
  # defaults to using .name and .id, but other methods can be specified, including Procs
  # if :tags is set, returns the <option> tags instead of just the array
  def sel_opts_from_objs(objs, options = {})
    # set default method names
    id_m = options[:id_method] ||= "id"
    name_m = options[:name_method] ||= "name"
    
    # get array of arrays
    arr = objs.collect do |o| 
      # get id and name array
      id = id_m.is_a?(Proc) ? id_m.call(o) : o.send(id_m)
      name = name_m.is_a?(Proc) ? name_m.call(o) : o.send(name_m)
      [name, id]
    end
    
    # wrap in tags if requested
    options[:tags] ? options_for_select(arr) : arr
  end
  
  # renders a collection of objects, including a boilerplate form and calls to the appropriate JS
  def collection_form(params)
    render(:partial => "layouts/collection_form", :locals => params)
  end
  
  # finds the english name of the language with the given code (e.g. 'French' for 'fr')
  # tries to use the translated locale name if it exists, otherwise use english language name from the iso639 gem
  # returns code itself if code not found
  def language_name(code)
    if configatron.locales.include?(code)
      t(:locale_name, :locale => code)
    else
      (entry = ISO_639.find(code.to_s)) ? entry.english_name : code.to_s
    end
  end
  
  # wraps the given content in a js tag and a jquery ready handler
  def javascript_doc_ready(&block)
    content = capture(&block)
    javascript_tag("$(document).ready(function(){#{content}});")
  end
  
  # takes an array of keys and a scope and builds an options array (e.g. [["Option 1", "opt1"], ["Option 2", "opt2"], ...])
  def translate_options(keys, scope)
    keys.map{|k| [t(k, :scope => scope), k]}
  end
  
  # generates a link like "Create New Option Set" given a klass
  # options[:js] - if true, the link just points to # with expectation that js will bind to it
  def create_link(klass, options = {})
    # get the link target path. honor the js option.
    href = options[:js] ? "#" : send("new_#{klass.model_name.singular_route_key}_path")
    
    link_to(t("#{klass.model_name.i18n_key}.create_link"), href, :class => "create_#{klass.model_name.param_key}")
  end
  
  # translates a boolean value
  def tbool(b)
    t(b ? "common._yes" : "common._no")
  end

  # if the given array is not paginated, apply an infinite pagination so the will_paginate methods will still work
  def ensure_paginated(objs)
    if !objs.respond_to?(:total_entries) && objs.respond_to?(:paginate)
      objs.paginate(:page => 1, :per_page => 1000000)
    else
      objs
    end
  end
  
  def translate_model(model)
    pluralize_model(model, :count => 1)
  end
  
  # gets or constructs the page title from the translation file or from an explicitly set @title
  # returns empty string if no translation found and no explicit title set
  def title
    # use explicit title if given
    return @title unless @title.nil?

    # if action specified outright, use that
    action = if @title_action
      @title_action
    else
      # use 'new' and 'edit' for 'update' and 'create', respectively
      case action_name
      when "update" then "edit"
      when "create" then "new"
      else action_name
      end
    end

    @title = t(action, {:scope => "page_titles.#{controller_name}", :default => [:all, ""]}.merge(@title_args || {}))
  end
  
  # pluralizes an activerecord model name
  # assumes 2 if count not given in options
  def pluralize_model(klass, options = {})
    t("activerecord.models.#{klass.model_name.i18n_key}", :count => options[:count] || 2)
  end
  
  # translates and interprets markdown markup
  def tmd(*args)
    # strip the outer <p> </p> tags
    BlueCloth.new(t(*args)).to_html[3..-5].html_safe
  end
end
