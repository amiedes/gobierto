<template>
  <div>
    <div class="pure-g gutters m_b_1">
      <div class="pure-u-1 pure-u-lg-4-4">
        <Nav
          :active-tab="activeTabIndex"
          @active-tab="activeTabIndex = $event"
        />
      </div>
      <Sidebar
        :active-tab="activeTab"
        :filters="filters"
        @active-tab-sidebar="activeTab = $event"
      />
      <component
        :is="currentComponent"
        :all-datasets="allDatasets"
      />
    </div>
  </div>
</template>
<script>
import Sidebar from "./../components/Sidebar.vue";
import Nav from "./../components/Nav.vue";
import InfoList from "./../components/commons/InfoList.vue";
import DataSets from "./../pages/DataSets.vue";
export default {
  name: "LayoutTabs",
  components: {
    Sidebar,
    DataSets,
    InfoList,
    Nav
  },
  props: {
    filters: {
      type: Array,
      default: () => []
    },
    allDatasets: {
      type: Array,
      default: () => []
    },
    currentView: {
      type: String,
      required: true,
      default: ''
    },
    currentTab: {
      type: Number,
      default: 0
    }
  },
  data() {
    return {
      activeTabIndex: 0,
      activeTab: 0,
      currentComponent: ''
    }
  },
  created() {
    this.currentComponent = this.currentView
    this.activeTab = this.currentTab
  }
}
</script>
