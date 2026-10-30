/// How much of a child's detail is shared with the parent.
///
/// This is a view filter, never a data mutation. The child always sees their
/// own full picture and can see which level is active.
enum VisibilityLevel { full, guided, trends }
