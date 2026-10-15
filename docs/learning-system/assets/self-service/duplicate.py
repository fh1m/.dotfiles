def first_duplicate(values):
    seen = set()
    for value in values:
        if value in seen:
            return value
        seen.add(value)
    return None
