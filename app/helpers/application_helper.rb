module ApplicationHelper
  include Pagy::Frontend

  def smart_date(date, threshold_days: 10)
    return "" if date.blank?

    days_ago = (Time.current.to_date - date.to_date).to_i
    if days_ago < threshold_days
      "#{time_ago_in_words(date)} ago"
    else
      date.strftime("%b %d, %Y")
    end
  end

  def icon(name, size: nil, css_class: nil)
    paths = {
      trash: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>',
      edit: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>',
      chevron_left: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>',
      chevron_right: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>',
      plus: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>',
      filter: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"></path>',
      bar_chart: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 20V10"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 20V4"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 20v-6"/>',
      copy: '<rect x="9" y="9" width="13" height="13" rx="2" ry="2" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"></rect><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"></path>',
      more_vertical: '<circle cx="12" cy="5" r="1" fill="currentColor"/><circle cx="12" cy="12" r="1" fill="currentColor"/><circle cx="12" cy="19" r="1" fill="currentColor"/>',
      eye: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>',
      board_grid: '<rect x="3" y="2" width="18" height="20" rx="2" stroke-width="1.5"/><line x1="3" y1="8.5" x2="21" y2="8.5" stroke-width="1.5"/><line x1="3" y1="15" x2="21" y2="15" stroke-width="1.5"/><line x1="9" y1="2" x2="9" y2="22" stroke-width="1.5"/><line x1="15" y1="2" x2="15" y2="22" stroke-width="1.5"/>',
      problem: '<rect x="3" y="2" width="18" height="20" rx="2" stroke-width="1.5"/><circle cx="8" cy="16" r="2" fill="currentColor" stroke="none"/><circle cx="15" cy="12" r="2" fill="currentColor" stroke="none"/><circle cx="10" cy="7" r="2" fill="currentColor" stroke="none"/>',
      calendar: '<rect x="3" y="4" width="18" height="18" rx="2" ry="2" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><line x1="16" y1="2" x2="16" y2="6" stroke-width="2" stroke-linecap="round"/><line x1="8" y1="2" x2="8" y2="6" stroke-width="2" stroke-linecap="round"/><line x1="3" y1="10" x2="21" y2="10" stroke-width="2" stroke-linecap="round"/>',
      barbell: '<line x1="2" y1="12" x2="22" y2="12" stroke-width="2" stroke-linecap="round"/><rect x="4" y="7" width="3" height="10" rx="1" stroke-width="2"/><rect x="17" y="7" width="3" height="10" rx="1" stroke-width="2"/><rect x="1" y="9" width="3" height="6" rx="1" stroke-width="2"/><rect x="20" y="9" width="3" height="6" rx="1" stroke-width="2"/>',
      boards: '<rect x="2" y="2" width="20" height="8" rx="2" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><rect x="2" y="14" width="20" height="8" rx="2" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>',
      tag: '<path stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M20.59 13.41l-7.17 7.17a2 2 0 01-2.83 0L2 12V2h10l8.59 8.59a2 2 0 010 2.82z"/><line x1="7" y1="7" x2="7.01" y2="7" stroke-width="2" stroke-linecap="round"/>',
      users: '<path stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4" stroke-width="2"/><path stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M23 21v-2a4 4 0 00-3-3.87"/><path stroke-width="2" d="M16 3.13a4 4 0 010 7.75"/>',
      gear: '<circle cx="12" cy="12" r="3" stroke-width="2"/><path stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83-2.83l.06-.06A1.65 1.65 0 004.68 15a1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 012.83-2.83l.06.06A1.65 1.65 0 009 4.68a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 2.83l-.06.06A1.65 1.65 0 0019.4 9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z"/>',
      help_circle: '<circle cx="12" cy="12" r="10" stroke-width="2"/><path stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M9.09 9a3 3 0 015.83 1c0 2-3 3-3 3"/><line x1="12" y1="17" x2="12.01" y2="17" stroke-width="2" stroke-linecap="round"/>',
      shield: '<path stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>',
      menu: '<line x1="3" y1="12" x2="21" y2="12" stroke-width="2" stroke-linecap="round"/><line x1="3" y1="6" x2="21" y2="6" stroke-width="2" stroke-linecap="round"/><line x1="3" y1="18" x2="21" y2="18" stroke-width="2" stroke-linecap="round"/>',
      download: '<path stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline stroke-width="2" stroke-linecap="round" stroke-linejoin="round" points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3" stroke-width="2" stroke-linecap="round"/>',
      github: '<path fill="currentColor" stroke="none" d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.4 3-.405 1.02.005 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/>'
    }

    css_class ||= size == :sm ? "icon-sm" : "icon"
    content = paths[name.to_sym] || ""
    %(<svg class="#{css_class}" fill="none" stroke="currentColor" viewBox="0 0 24 24">#{content}</svg>).html_safe
  end
end
