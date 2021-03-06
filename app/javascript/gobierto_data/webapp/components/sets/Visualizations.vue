<template>
  <div class="gobierto-data-sets-nav--tab-container">
    <template v-if="isUserLoggged">
      <Dropdown>
        <template v-slot:trigger>
          <h3 class="gobierto-data-visualization--h3">
            {{ labelVisPrivate }}
            <template v-if="privateVisualizations.length">
              ({{ privateVisualizations.length }})
            </template>
          </h3>
        </template>

        <div class="gobierto-data-visualization--grid">
          <template v-if="isPrivateLoading">
            <Spinner />
          </template>

          <template v-else>
            <template v-if="privateVisualizations.length">
              <template v-for="{ data, config, name } in privateVisualizations">
                <div :key="name">
                  <div class="gobierto-data-visualization--card">
                    <div class="gobierto-data-visualization--aspect-ratio-16-9">
                      <div class="gobierto-data-visualization--content">
                        <h4 class="gobierto-data-visualization--title">
                          {{ name }}
                        </h4>
                        <SQLEditorVisualizations
                          :items="data"
                          :config="config"
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </template>
            </template>

            <template v-else>
              <div>{{ labelVisEmpty }}</div>
            </template>
          </template>
        </div>
      </Dropdown>
    </template>

    <Dropdown>
      <template v-slot:trigger>
        <h3 class="gobierto-data-visualization--h3">
          {{ labelVisPublic }}
          <template v-if="publicVisualizations.length">
            ({{ publicVisualizations.length }})
          </template>
        </h3>
      </template>

      <div class="gobierto-data-visualization--grid">
        <template v-if="isPublicLoading">
          <Spinner />
        </template>

        <template v-else>
          <template v-if="publicVisualizations.length">
            <template v-for="{ data, config, name } in publicVisualizations">
              <div :key="name">
                <div class="gobierto-data-visualization--card">
                  <div class="gobierto-data-visualization--aspect-ratio-16-9">
                    <div class="gobierto-data-visualization--content">
                      <h4 class="gobierto-data-visualization--title">
                        {{ name }}
                      </h4>
                      <SQLEditorVisualizations
                        :items="data"
                        :config="config"
                      />
                    </div>
                  </div>
                </div>
              </div>
            </template>
          </template>

          <template v-else>
            <div>{{ labelVisEmpty }}</div>
          </template>
        </template>
      </div>
    </Dropdown>
  </div>
</template>
<script>
import SQLEditorVisualizations from "./SQLEditorVisualizations.vue";
import Spinner from "./../commons/Spinner.vue";
import { Dropdown } from "lib/vue-components";
import { VisualizationFactoryMixin } from "./../../../lib/factories/visualizations";
import { QueriesFactoryMixin } from "./../../../lib/factories/queries";
import { DataFactoryMixin } from "./../../../lib/factories/data";
import { getUserId } from "./../../../lib/helpers";

export default {
  name: "Visualizations",
  components: {
    SQLEditorVisualizations,
    Spinner,
    Dropdown
  },
  mixins: [VisualizationFactoryMixin, QueriesFactoryMixin, DataFactoryMixin],
  props: {
    datasetId: {
      type: Number,
      required: true
    }
  },
  data() {
    return {
      labelVisEmpty: "",
      labelVisPrivate: "",
      labelVisPublic: "",
      publicVisualizations: [],
      privateVisualizations: [],
      isUserLoggged: false,
      isPrivateLoading: false,
      isPublicLoading: false
    };
  },
  created() {
    this.labelVisEmpty = I18n.t("gobierto_data.projects.visEmpty");
    this.labelVisPrivate = I18n.t("gobierto_data.projects.visPrivate");
    this.labelVisPublic = I18n.t("gobierto_data.projects.visPublic");

    this.userId = getUserId();
    this.isUserLoggged = !!this.userId;

    // Get all visualizations
    this.getPrivateVisualizations();
    this.getPublicVisualizations();
  },
  methods: {
    async getPublicVisualizations() {
      this.isPublicLoading = true

      const { data: response } = await this.getVisualizations({
        "filter[dataset_id]": this.datasetId
      });
      const { data } = response;

      if (data.length) {
        this.publicVisualizations = await this.getDataFromVisualizations(data);
      }

      this.isPublicLoading = false
    },
    async getPrivateVisualizations() {
      this.isPrivateLoading = true

      if (this.userId) {
        const { data: response } = await this.getVisualizations({
          "filter[dataset_id]": this.datasetId,
          "filter[user_id]": this.userId
        });
        const { data } = response;

        if (data.length) {
          this.privateVisualizations = await this.getDataFromVisualizations(
            data
          );
        }
      }

      this.isPrivateLoading = false
    },
    async getDataFromVisualizations(data) {
      const visualizations = [];
      for (let index = 0; index < data.length; index++) {
        const { attributes = {} } = data[index];
        const { query_id: id, spec = {}, name = "" } = attributes;

        let queryData = null;

        if (id) {
          // Get my queries, if they're stored
          const { data } = await this.getQuery(id);
          queryData = data;
        } else {
          // Otherwise, run the sql
          const { sql } = attributes;
          const { data } = await this.getData({ sql });
          queryData = data;
        }

        // Append the visualization configuration
        const visualization = { ...queryData, config: spec, name };

        visualizations.push(visualization);
      }

      return visualizations;
    }
  }
};
</script>
