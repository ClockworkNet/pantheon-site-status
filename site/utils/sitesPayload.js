export function parseSitesPayload (payload) {
  if (Array.isArray(payload)) {
    return { list: payload, generatedAt: null }
  }

  return {
    list: Array.isArray(payload && payload.sites) ? payload.sites : [],
    generatedAt: payload && payload.generated_at ? payload.generated_at : null
  }
}

export function formatGeneratedAt (iso) {
  if (!iso) {
    return ''
  }

  const date = new Date(iso)
  if (Number.isNaN(date.getTime())) {
    return ''
  }

  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    timeZone: 'UTC'
  })
}
