/*
 * Copyright (c) 2021 Airbyte, Inc., all rights reserved.
 */

package io.airbyte.integrations.destination.e2e_test;

import com.fasterxml.jackson.databind.JsonNode;
import com.google.common.collect.ImmutableMap;
import io.airbyte.integrations.BaseConnector;
import io.airbyte.integrations.base.AirbyteMessageConsumer;
import io.airbyte.integrations.base.Destination;
import io.airbyte.integrations.base.IntegrationRunner;
import io.airbyte.protocol.models.AirbyteConnectionStatus;
import io.airbyte.protocol.models.AirbyteMessage;
import io.airbyte.protocol.models.ConfiguredAirbyteCatalog;
import java.util.Map;
import java.util.function.Consumer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class TestingDestinations extends BaseConnector implements Destination {

  private static final Logger LOGGER = LoggerFactory.getLogger(TestingDestinations.class);

  private final Map<TestDestinationType, Destination> destinationMap;

  public enum TestDestinationType {
    LOGGING,
    THROTTLED,
    SILENT
  }

  public TestingDestinations() {
    this(ImmutableMap.<TestDestinationType, Destination>builder()
        .put(TestDestinationType.LOGGING, new LoggingDestination())
        .put(TestDestinationType.THROTTLED, new ThrottledDestination())
        .put(TestDestinationType.SILENT, new SilentDestination())
        .build());
  }

  public TestingDestinations(Map<TestDestinationType, Destination> destinationMap) {
    this.destinationMap = destinationMap;
  }

  private Destination selectDestination(JsonNode config) {
    return destinationMap.get(TestDestinationType.valueOf(config.get("type").asText()));
  }

  @Override
  public AirbyteMessageConsumer getConsumer(final JsonNode config,
                                            final ConfiguredAirbyteCatalog catalog,
                                            final Consumer<AirbyteMessage> outputRecordCollector)
      throws Exception {
    return selectDestination(config).getConsumer(config, catalog, outputRecordCollector);
  }

  @Override
  public AirbyteConnectionStatus check(final JsonNode config) throws Exception {
    return selectDestination(config).check(config);
  }

  public static void main(String[] args) throws Exception {
    final Destination destination = new TestingDestinations();
    LOGGER.info("starting destination: {}", TestingDestinations.class);
    new IntegrationRunner(destination).run(args);
    LOGGER.info("completed destination: {}", TestingDestinations.class);
  }

}
