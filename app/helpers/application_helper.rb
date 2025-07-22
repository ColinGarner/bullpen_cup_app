module ApplicationHelper
  def match_status_badge(match)
    case match.status
    when "upcoming"
      content_tag :span, "Upcoming", class: "inline-block px-2 py-1 text-xs font-semibold rounded-full bg-blue-100 text-blue-800"
    when "active"
      content_tag :span, "Live", class: "inline-block px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800"
    when "completed"
      content_tag :span, "Completed", class: "inline-block px-2 py-1 text-xs font-semibold rounded-full bg-gray-100 text-gray-800"
    when "cancelled"
      content_tag :span, "Cancelled", class: "inline-block px-2 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-800"
    end
  end

  def next_hole_for_user(match, user)
    # Find the highest hole number this user has scored in this match
    last_scored_hole = match.scores.where(user: user).where.not(strokes: 0).maximum(:hole_number) || 0

    # If all holes are complete, go to hole 18 to view/edit
    return 18 if last_scored_hole >= 18

    # Return the next hole that needs scoring
    last_scored_hole + 1
  end
end
