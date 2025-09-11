{{- define "envoy.config" -}}
overload_manager:
  refresh_interval: 0.25s
  resource_monitors:
    - name: "envoy.resource_monitors.fixed_heap"
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.resource_monitors.fixed_heap.v3.FixedHeapConfig
        max_heap_size_bytes: {{ include "_getGwProxyOverloadManagerMaxHeapSize" . }}
  actions:
    - name: "envoy.overload_actions.shrink_heap"
      triggers:
        - name: "envoy.resource_monitors.fixed_heap"
          threshold:
            value: 0.95
    - name: "envoy.overload_actions.stop_accepting_requests"
      triggers:
        - name: "envoy.resource_monitors.fixed_heap"
          threshold:
            value: 0.98
layered_runtime:
  layers:
    - name: static_layer_0
      static_layer:
        envoy:
          resource_limits:
            listener:
              example_listener_name:
                connection_limit: 2000
        overload:
          global_downstream_max_connections: 4000
admin:
  address:
    socket_address:
      address: "::"
      ipv4_compat: true
      port_value: 8000
node:
  cluster: test-cluster
  id: test-id
dynamic_resources:
  cds_config:
    resource_api_version: "v3"
    path_config_source:
      path: /etc/envoy/cds.yaml
  lds_config:
    resource_api_version: "v3"
    path_config_source:
      path: /etc/envoy/lds.yaml
{{- end }}
{{- define "envoy.cds" -}}
---
resources:
  - "@type": type.googleapis.com/envoy.config.cluster.v3.Cluster
    name: gateway_http
    connect_timeout: 5s
    per_connection_buffer_limit_bytes: 32768  # 32 KiB
    type: STRICT_DNS
    load_assignment:
      cluster_name: gateway_http
      endpoints:
        - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: gateway-headless
                    port_value: 8080
  - "@type": type.googleapis.com/envoy.config.cluster.v3.Cluster
    name: gateway_grpc
    connect_timeout: 5s
    per_connection_buffer_limit_bytes: 32768  # 32 KiB
    type: STRICT_DNS
    load_assignment:
      cluster_name: gateway_grpc
      endpoints:
        - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: gateway-headless
                    port_value: {{ .Values.gateway.ports.serviceGrpcPort }}
    circuit_breakers:
      thresholds:
        - priority: DEFAULT
          max_connections: {{ .Values.gwProxy.circuitBreakers.maxConnections }}
          max_pending_requests: {{ .Values.gwProxy.circuitBreakers.maxRequests }}
          max_requests: {{ .Values.gwProxy.circuitBreakers.maxRequests }}
          max_retries: 3
        - priority: HIGH
          max_connections: {{ .Values.gwProxy.circuitBreakers.maxConnections }}
          max_pending_requests: {{ .Values.gwProxy.circuitBreakers.maxRequests }}
          max_requests: {{ .Values.gwProxy.circuitBreakers.maxRequests }}
          max_retries: 3
    typed_extension_protocol_options:
      envoy.extensions.upstreams.http.v3.HttpProtocolOptions:
        "@type": type.googleapis.com/envoy.extensions.upstreams.http.v3.HttpProtocolOptions
        explicit_http_config:
          http2_protocol_options:
            max_concurrent_streams: 100
            initial_stream_window_size: 65536  # 64 KiB
            initial_connection_window_size: 1048576  # 1 MiB
    {{- if and ((.Values.logStore).enabled) (eq ((.Values.logStore).deploymentMode) "dedicatedService") }}
  - "@type": type.googleapis.com/envoy.config.cluster.v3.Cluster
    name: log-store_grpc
    connect_timeout: 5s
    per_connection_buffer_limit_bytes: 32768  # 32 KiB
    type: STRICT_DNS
    load_assignment:
      cluster_name: log-store_grpc
      endpoints:
        - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: log-store-headless
                    port_value: 50051
    circuit_breakers:
      thresholds:
        - priority: DEFAULT
          max_connections: {{ .Values.gwProxy.circuitBreakers.maxConnections }}
          max_pending_requests: {{ .Values.gwProxy.circuitBreakers.maxRequests }}
          max_requests: {{ .Values.gwProxy.circuitBreakers.maxRequests }}
          max_retries: 3
        - priority: HIGH
          max_connections: {{ .Values.gwProxy.circuitBreakers.maxConnections }}
          max_pending_requests: {{ .Values.gwProxy.circuitBreakers.maxRequests }}
          max_requests: {{ .Values.gwProxy.circuitBreakers.maxRequests }}
          max_retries: 3
    typed_extension_protocol_options:
      envoy.extensions.upstreams.http.v3.HttpProtocolOptions:
        "@type": type.googleapis.com/envoy.extensions.upstreams.http.v3.HttpProtocolOptions
        explicit_http_config:
          http2_protocol_options:
            max_concurrent_streams: 100
            initial_stream_window_size: 65536  # 64 KiB
            initial_connection_window_size: 1048576  # 1 MiB
    {{- end }}
{{- end }}
{{- define "envoy.lds" -}}
---
resources:
  - "@type": type.googleapis.com/envoy.config.listener.v3.Listener
    name: listener_8001
    address:
      socket_address:
        address: "::"
        ipv4_compat: true
        port_value: 8001
    per_connection_buffer_limit_bytes: 32768  # 32 KiB
    filter_chains:
      - filters:
          - name: envoy.filters.network.http_connection_manager
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
              codec_type: auto
              stat_prefix: ingress_8001
              route_config:
                name: search_route
                virtual_hosts:
                  - name: metrics
                    domains:
                      - "*"
                    routes:
                      - match:
                          path: "/healthz"
                        direct_response:
                          status: 200
  - "@type": type.googleapis.com/envoy.config.listener.v3.Listener
    name: listener_8080
    address:
      socket_address:
        address: "::"
        ipv4_compat: true
        port_value: 8080
    per_connection_buffer_limit_bytes: 32768  # 32 KiB
    filter_chains:
      - filters:
          - name: envoy.filters.network.http_connection_manager
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
              codec_type: auto
              stat_prefix: ingress_8080
              common_http_protocol_options:
                idle_timeout: 3600s
              http2_protocol_options:
                initial_stream_window_size: 65536  # 64 KiB
                initial_connection_window_size: 1048576  # 1 MiB
              stream_idle_timeout: 600s
              request_timeout: 600s # 10 minutes for http endpoint requests
              http_filters:
                - name: envoy.filters.http.router
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
              access_log:
                - name: envoy.access_loggers.file
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
                    path: /dev/stdout
              route_config:
                name: search_route
                virtual_hosts:
                  - name: metrics
                    domains:
                      - "*"
                    routes:
                      - match:
                          path: "/"
                        direct_response:
                          status: 200
                          body:
                            inline_string: "Azul Optimizer Hub - serves JVMs"
                      # Internal /q/health endpoint routed to the gateway Quarkus /q/health endpoint
                      # This is here for compatibility reasons. It is not the healtcheck intended to be used externally
                      # to decide status of Opthub cluster, e.g. for the use by load balancers.
                      - match:
                           path: "/q/health"
                        route:
                          timeout: 600s
                          cluster: gateway_http
                          prefix_rewrite: "/q/health"
                      - match:
                           path: "/opthub-health"
                        route:
                          timeout: 600s
                          cluster: gateway_http
                          prefix_rewrite: "/api/opthub-health/healthy"
                      # Catch-all route for all other URLs
                      - match:
                          prefix: "/"    # Match all paths starting with "/"
                        direct_response:
                          status: 404
                          body:
                            inline_string: "no resource"
  - "@type": type.googleapis.com/envoy.config.listener.v3.Listener
    name: listener_grpc_service
    address:
      socket_address:
        address: "::"
        ipv4_compat: true
        port_value: {{ .Values.gateway.ports.serviceGrpcPort }}
{{- if .Values.ssl.enabled }}
    listener_filters:
      - name: "envoy.filters.listener.tls_inspector"
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.listener.tls_inspector.v3.TlsInspector
{{- end }}
    per_connection_buffer_limit_bytes: 32768  # 32 KiB
    filter_chains:
      - filters:
          - name: envoy.filters.network.http_connection_manager
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
              codec_type: auto
              stat_prefix: ingress_grpc
              common_http_protocol_options:
                idle_timeout: 3600s
              http2_protocol_options:
                initial_stream_window_size: 65536  # 64 KiB
                initial_connection_window_size: 1048576  # 1 MiB
              stream_idle_timeout: 600s
              http_filters:
                - name: envoy.filters.http.grpc_stats
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.filters.http.grpc_stats.v3.FilterConfig
                - name: envoy.filters.http.router
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
              access_log:
                - name: envoy.access_loggers.file
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
                    path: /dev/stdout
                    log_format:
                      text_format_source:
                        inline_string: >
                          [%START_TIME%] "%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%"
                          %RESPONSE_CODE% %GRPC_STATUS(SNAKE_STRING)% %RESPONSE_FLAGS% %BYTES_RECEIVED% %BYTES_SENT%
                          %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% "%REQ(X-FORWARDED-FOR)%" "%REQ(USER-AGENT)%"
                          "%REQ(X-REQUEST-ID)%" "%REQ(:AUTHORITY)%" "%UPSTREAM_HOST%"

              route_config:
                name: search_route
                virtual_hosts:
                  - name: metrics
                    domains:
                      - "*"
                    routes:
                      {{- if and ((.Values.logStore).enabled) (eq ((.Values.logStore).deploymentMode) "dedicatedService") }}
                      - match:
                          prefix: "/azul.opthub.logstore.LogStoreService"
                        route:
                          timeout: 600s
                          cluster: log-store_grpc
                      {{- end }}
                      - match:
                          prefix: "/"
                        route:
                          timeout: 600s
                          cluster: gateway_grpc
{{- if .Values.ssl.enabled }}
        transport_socket:
          name: envoy.transport_sockets.tls
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
            common_tls_context:
              alpn_protocols: "h2,http/1.1"
              tls_certificates:
                - certificate_chain:
                    filename: "/opt/ssl/{{ .Values.ssl.path.cert }}"
                  private_key:
                    filename: "/opt/ssl/{{ .Values.ssl.path.key }}"
{{- end }}
{{- end }}
