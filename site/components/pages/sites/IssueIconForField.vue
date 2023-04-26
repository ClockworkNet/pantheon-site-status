<template>
  <div>
    <PagesSitesIssueIcon :issue="matchingIssue"></PagesSitesIssueIcon>
  </div>
</template>
<script>
export default {
  props: [
    'fieldName',
    'site'
  ],
  mounted() {
    console.info('test', this.site);
  },
  computed: {
    matchingIssue() {
      return this.site.issues.find(issue => issue.related_field === this.fieldName);
    }
  }
}
</script>
