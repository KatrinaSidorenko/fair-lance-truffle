const EscrowManager = artifacts.require("EscrowManager");

contract("EscrowManager – Freelance Workflow", (accounts) => {
  const [employer, freelancer] = accounts;
  const jobId = 1;

  let escrow;

  before(async () => {
    escrow = await EscrowManager.deployed();
  });

  it("Employer publishes and funds a job", async () => {
    const tx = await escrow.publishJob(jobId, {
      from: employer,
      value: web3.utils.toWei("1", "ether"),
    });

    // Check event
    const event = tx.logs[0];
    assert.equal(event.event, "JobPublished", "JobPublished event not emitted");

    const job = await escrow.jobs(jobId);
    assert.equal(job.employer, employer, "Employer not set correctly");
    assert.equal(job.funded, true, "Job not marked as funded");

    const contractBalance = await web3.eth.getBalance(escrow.address);
    assert.equal(
      contractBalance,
      web3.utils.toWei("1", "ether"),
      "Escrow balance incorrect"
    );
  });

  it("Employer assigns a freelancer", async () => {
    await escrow.assignExecutor(jobId, freelancer, { from: employer });

    const job = await escrow.jobs(jobId);
    assert.equal(job.freelancer, freelancer, "Freelancer not assigned");
  });

  it("Employer approves job and releases funds to pending withdrawals", async () => {
    const tx = await escrow.approveJob(jobId, { from: employer });

    const event = tx.logs[0];
    assert.equal(event.event, "JobApproved", "JobApproved event not emitted");

    const pending = await escrow.pendingWithdrawals(jobId);
    assert.equal(
      pending.toString(),
      web3.utils.toWei("1", "ether"),
      "Pending withdrawal amount incorrect"
    );

    const job = await escrow.jobs(jobId);
    assert.equal(job.approved, true, "Job not approved");
  });

  it("Freelancer withdraws approved funds", async () => {
    const balanceBefore = web3.utils.toBN(
      await web3.eth.getBalance(freelancer)
    );

    const tx = await escrow.withdraw(jobId, { from: freelancer });

    const event = tx.logs[0];
    assert.equal(event.event, "Withdrawn", "Withdrawn event not emitted");

    const balanceAfter = web3.utils.toBN(
      await web3.eth.getBalance(freelancer)
    );

    assert(
      balanceAfter.gt(balanceBefore),
      "Freelancer balance did not increase"
    );

    const pending = await escrow.pendingWithdrawals(jobId);
    assert.equal(pending.toString(), "0", "Pending withdrawal not cleared");

    const job = await escrow.jobs(jobId);
    assert.equal(job.completed, true, "Job not marked as completed");
  });

  it("Freelancer cannot withdraw funds before approval", async () => {
  const newJobId = 2;

  // Employer publishes and funds a new job
  await escrow.publishJob(newJobId, {
    from: employer,
    value: web3.utils.toWei("1", "ether"),
  });

  // Employer assigns freelancer
  await escrow.assignExecutor(newJobId, freelancer, { from: employer });

  // Attempt to withdraw BEFORE approval
  try {
    await escrow.withdraw(newJobId, { from: freelancer });
    assert.fail("Withdraw should have reverted");
  } catch (error) {
    assert(
      error.message.includes("Job not approved"),
      "Expected revert with 'Job not approved'"
    );
  }
  });
});

