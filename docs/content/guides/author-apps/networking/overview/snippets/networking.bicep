import radius as radius

param environment string

resource app 'Applications.Core/applications@2023-10-01-preview' = {
  name: 'myapp'
  properties: {
    environment: environment
  }
}

resource serviceA 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'service-a'
  properties: {
    application: app.id
    container: {
      image: 'servicea'
      ports: {
        web: {
          containerPort: 80
          provides: routeAWeb.id
        }
        api: {
          containerPort: 3000
          provides: routeAApi.id
        }
      }
    }
    connections: {
      serviceB: {
        source: routeB.id
      }
    }
  }
}

resource routeAWeb 'Applications.Core/httpRoutes@2023-10-01-preview' = {
  name: 'route-a-web'
  properties: {
    application: app.id
  }
}

resource routeAApi 'Applications.Core/httpRoutes@2023-10-01-preview' = {
  name: 'route-a-api'
  properties: {
    application: app.id
  }
}

resource serviceB 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'service-b'
  properties: {
    application: app.id
    container: {
      image: 'serviceb'
      ports: {
        api: {
          containerPort: 3000
          provides: routeB.id
        }
      }
    }
    connections: {
      serviceA: {
        source: routeAApi.id
      }
    }
  }
}

resource routeB 'Applications.Core/httpRoutes@2023-10-01-preview' = {
  name: 'route-b'
  properties: {
    application: app.id
  }
}

resource internetGateway 'Applications.Core/gateways@2023-10-01-preview' = {
  name: 'internet-gateway'
  properties: {
    application: app.id
    routes: [
      {
        path: '/'
        destination: routeAWeb.id
      }
    ]
  }
}