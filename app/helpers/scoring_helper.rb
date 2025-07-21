module ScoringHelper
  def difficulty_label(yardage)
    case yardage
    when 0..5500
      "Beginner Friendly"
    when 5501..6200
      "Intermediate"
    when 6201..6800
      "Challenging"
    when 6801..7200
      "Advanced"
    else
      "Championship"
    end
  end

  def difficulty_percentage(yardage)
    # Scale yardage to percentage (5000 = 0%, 7500 = 100%)
    min_yards = 5000
    max_yards = 7500
    
    percentage = ((yardage - min_yards).to_f / (max_yards - min_yards) * 100).round
    [[percentage, 0].max, 100].min # Clamp between 0 and 100
  end

  def format_score_display(score)
    return "—" if score.nil? || score.zero?
    score.to_s
  end

  def hole_difficulty_class(hole_handicap)
    case hole_handicap
    when 1..6
      "text-red-600 font-bold" # Hardest holes
    when 7..12
      "text-yellow-600 font-semibold" # Medium holes
    else
      "text-green-600" # Easier holes
    end
  end

  def tee_options_grouped
    return [] unless @available_tees

    # Group tees by gender
    grouped_tees = @available_tees.group_by { |tee| tee[:gender] }
    
    options = []
    
    # Add men's tees first
    if grouped_tees['male']
      male_options = grouped_tees['male'].map do |tee|
        label = "#{tee[:name]} - #{tee[:rating]}/#{tee[:slope]} - #{number_with_delimiter(tee[:yardage])} yards"
        [label, tee[:name]]
      end
      options << ["Men's", male_options]
    end
    
    # Add women's tees
    if grouped_tees['female']
      female_options = grouped_tees['female'].map do |tee|
        label = "#{tee[:name]} - #{tee[:rating]}/#{tee[:slope]} - #{number_with_delimiter(tee[:yardage])} yards"
        [label, tee[:name]]
      end
      options << ["Women's", female_options]
    end
    
    options
  end
end
