exports.handler = async function () {
    return {
      statusCode: 500,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        error: "create-session function exists but is not wired yet",
      }),
    };
  };