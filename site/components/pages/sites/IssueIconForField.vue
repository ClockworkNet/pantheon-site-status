<template>
  <div>
    <PagesSitesIssueIcon :issue="matchingIssue" />
  </div>
</template>
<script>
export default {
  props: [
    'fieldName',
    'site'
  ],
  computed: {
    matchingIssue () {
      return this.site.issues.find(issue => issue.related_field === this.fieldName)
    }
  },
  mounted () {
    console.info('test', this.site)
  }
}
</script>
