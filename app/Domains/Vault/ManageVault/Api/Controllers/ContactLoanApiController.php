<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageLoans\Services\CreateLoan;
use App\Domains\Contact\ManageLoans\Services\DestroyLoan;
use App\Domains\Contact\ManageLoans\Services\ToggleLoan;
use App\Domains\Contact\ManageLoans\Services\UpdateLoan;
use Illuminate\Http\Request;

/**
 * @group Contact management
 *
 * @subgroup Loans
 */
class ContactLoanApiController extends ContactModuleApiController
{
    public function store(Request $request, string $vaultId, string $contactId)
    {
        (new CreateLoan)->execute($this->baseData($request, $vaultId, $contactId) + [
            'type' => $request->input('type', 'object'),
            'name' => $request->input('name'),
            'description' => $request->input('description'),
            'amount_lent' => $request->input('amount_lent'),
            'currency_id' => $request->input('currency_id'),
            'loaned_at' => $request->input('loaned_at'),
            'loaner_ids' => $request->input('loaner_ids', []),
            'loanee_ids' => $request->input('loanee_ids', []),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function update(Request $request, string $vaultId, string $contactId, string $loanId)
    {
        (new UpdateLoan)->execute($this->baseData($request, $vaultId, $contactId) + [
            'loan_id' => (int) $loanId,
            'type' => $request->input('type', 'object'),
            'name' => $request->input('name'),
            'description' => $request->input('description'),
            'amount_lent' => $request->input('amount_lent'),
            'currency_id' => $request->input('currency_id'),
            'loaned_at' => $request->input('loaned_at'),
            'loaner_ids' => $request->input('loaner_ids', []),
            'loanee_ids' => $request->input('loanee_ids', []),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function destroy(Request $request, string $vaultId, string $contactId, string $loanId)
    {
        (new DestroyLoan)->execute($this->baseData($request, $vaultId, $contactId) + [
            'loan_id' => (int) $loanId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    /**
     * Toggle a loan between settled and outstanding.
     */
    public function toggle(Request $request, string $vaultId, string $contactId, string $loanId)
    {
        (new ToggleLoan)->execute($this->baseData($request, $vaultId, $contactId) + [
            'loan_id' => (int) $loanId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
