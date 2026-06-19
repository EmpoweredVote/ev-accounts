# ev-accounts

Backend that owns politician, candidate, and election data and resolves a location (address or
area) to the set of officials and races that govern it.

## Language

**Role**:
What a person does in a body, independent of where — "Representative", "Senator", "Mayor",
"Assessor", "Council Member". Belongs in `office_title` and nothing else.
_Avoid_: putting the district or jurisdiction here

**Chamber / Body**:
The governing body a role sits in — "Utah House of Representatives", "Salt Lake City Council",
"U.S. House of Representatives". The grouping level in the UI.
_Avoid_: office (overloaded)

**Seat designation**:
Which seat within a chamber a person holds — "District 24", "At-Large", "Ward 3", or empty for
single-seat offices (Governor, President, statewide Senator). The card subtitle.
_Avoid_: district_id (currently inconsistent), district_label (currently overloaded)

**Jurisdiction**:
The geographic area a body governs — "Salt Lake County", "Utah", "United States". Distinct from a
seat designation; never rendered as a district.

**Address path**:
Resolving a single point against all covering geofence boundaries — returns exactly one seat per
chamber. The proven, correct resolution.

**Browse / Area path**:
Resolving a whole area (city/county geo_id) rather than a point. An area overlaps many seats, so it
must return the full overlapping stack (county + school + every overlapping legislative district),
each listed separately — never lumped under one district label.
_Avoid_: treating browse as "this-government-only"
