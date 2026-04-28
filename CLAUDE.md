# Claude Instructions

## Development Guidelines
- Follow Rails best practices
- Always use hotwire for front end work and minimize use of javascript.
- When javascript is needed, always use Stimulus.
- Use RESTful routes primarily
- Follow Rails conventions for route structure
- Don t spin up a rails server to test a response. Rely on tests.

### CSS Guidelines

- Pure CSS only, no Tailwind
- No inline styles
- Add utility classes to application.css when needed
- Site uses dark mode theme with neon accent colors
- Gray scale is inverted: `--color-gray-900` is light (for text), `--color-gray-100` is dark

### Mobile-First Design

- Write CSS mobile-first: default styles for mobile, use `@media (min-width: 1024px)` for desktop
- Keep mobile layouts simple and single-column
- Use query params for filter/sort state (bookmarkable, works with Turbo)
- Desktop can progressively enhance with sidebars or multi-column layouts
- Touch targets should be at least 44px for mobile usability

### Icons

- Use existing icons from `ApplicationHelper#icon` for standard CRUD actions:
  - `:eye` for show/view
  - `:edit` for edit
  - `:trash` for delete
  - `:plus` for create/add
  - `:copy` for duplicate
  - `:bar_chart` for charts/stats
- Add new icons to the helper when needed, following the same SVG pattern

### Domain Modeling (DHH / 37signals style)

- No `app/services/` directory — put domain objects in `app/models/`
- Name classes after the concept, not a verb (`ActivityExport`, `Charts::Climbing`, `Kilter::Sync`) — never `*Service`, `*Manager`, `*Handler`
- Use namespaces to group related concepts (`Imports::Thecrag`, `Kilter::Client`, `Charts::Week`)
- Nest helpers under their aggregate when they only serve it (e.g. `ActivityLog::Loggables` lives at `app/models/activity_log/loggables.rb`)
- POROs are fine — they don't need to inherit from `ApplicationRecord` to live in `app/models/`

### Authorization

- Always scope record lookups through the current user: `current_user.boards.find(params[:id])`, never `Board.find(params[:id])`
- For associations that aren't directly on the user, scope through a chain (`@board.problems.find(...)`) or a join that ends at `current_user`
- Authorization must happen at the load, not after — avoid `Model.find` followed by an ownership check

### Code Quality

- Apply rubocop linting
- Run `rubocop` to check code style and fix issues before committing
- No `console.log` in committed JavaScript — strip debug logs before finishing
