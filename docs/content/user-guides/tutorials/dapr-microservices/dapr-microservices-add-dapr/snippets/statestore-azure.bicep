resource app 'radius.dev/Application@v1alpha3' = {
  name: 'dapr-tutorial'

  //BACKEND
  resource backend 'Container' = {
    name: 'backend'
    properties: {
      container: {
        image: 'radius.azurecr.io/daprtutorial-backend'
        ports: {
          orders: {
            containerPort: 3000
          }
        }
      }
      connections: {
        orders: {
          kind: 'dapr.io/StateStore'
          source: ordersStateStore.id
        }
      }
      traits: [
        {
          kind: 'dapr.io/Sidecar@v1alpha1'
          appId: 'backend'
          appPort: 3000
          provides: daprBackend.id
        }
      ]
    }
  }
  //BACKEND

  //ROUTE
  resource daprBackend 'dapr.io.InvokeHttpRoute' = {
    name: 'dapr-backend'
    properties: {
      appId: 'backend'
    }
  }
  //ROUTE

  // Reference the Dapr state store deployed by the starter - temporary workaround
  resource ordersStateStore 'dapr.io.StateStore' existing = {
    name: 'orders'
  }

}

// Use a starter module to deploy an Azure storage account and configure a Dapr state store
module stateStoreStarter 'br:radius.azurecr.io/starters/dapr-statestore-azure-tablestorage:latest' = {
  name: 'orders-statestore-starter'
  params: {
    radiusApplication: app
    stateStoreName: 'orders'
  }
}
