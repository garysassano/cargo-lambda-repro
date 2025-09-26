use lambda_runtime::{service_fn, Error, LambdaEvent};
use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
struct Request {
    command: String,
}

#[derive(Serialize)]
struct Response {
    message: String,
}

async fn function_handler(event: LambdaEvent<Request>) -> Result<Response, Error> {
    let command = event.payload.command;
    let message = format!("Hello from Lambda! You said: {}", command);

    Ok(Response { message })
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .with_target(false)
        .without_time()
        .init();

    lambda_runtime::run(service_fn(function_handler)).await
}
